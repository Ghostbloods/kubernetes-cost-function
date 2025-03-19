#-------------------------
#  GKe Cluster
# -------------------------
resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  remove_default_node_pool = true # We'll create a custom node pool
  initial_node_count       = 1    # Required by GCP

  network    = "default"
  subnetwork = "default"

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"

  }
  deletion_protection = false # Allow for cluster deletion
}
#
# Create a custom node pool
# This is where we'll deploy our application
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.gke_cluster.name
  project  = var.project_id

  node_count = var.node_count

  node_config {
    disk_size_gb    = 30 # Limit of 400 gb total for free tier
    machine_type    = var.machine_type
    preemptible     = true
    service_account = "terraform-sa@${var.project_id}.iam.gserviceaccount.com" # Use the service account created earlier

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Required for Workload Identity
    ]
  }
}

###################################
# Pub/Sub: scale-alerts-topic
###################################
resource "google_pubsub_topic" "scale_alerts_topic" {
  name = "scale-alerts-topic"
  project = var.project_id
}

# -------------------------
#  Service Account for Pub/Sub Push
# -------------------------
resource "google_service_account" "pubsub_push_sa" {
  account_id   = "pubsub-push-sa"
  display_name = "Pub/Sub Push Service Account"
  project      = var.project_id
}

# Let this service account invoke the Cloud Run Scaler
resource "google_project_iam_binding" "allow_pubsub_push_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"

  members = [
    "serviceAccount:${google_service_account.pubsub_push_sa.email}"
  ]
}
# -------------------------
#  Pub/Sub Subscription
# -------------------------
resource "google_pubsub_subscription" "scale_alerts_sub" {
  name  = "scale-alerts-subscription"
  topic = google_pubsub_topic.scale_alerts_topic.name
  project = var.project_id

  ack_deadline_seconds = 20

  # We'll fill the push_endpoint after we create the Scaler Cloud Run service
  push_config {
    push_endpoint = "https://scaler-77245052764.us-central1.run.app"
    oidc_token {
      service_account_email = google_service_account.pubsub_push_sa.email
    }
  }
  depends_on = [google_cloud_run_service.scaler]
}
# -------------------------
#  Pub/Sub Role
# -------------------------

resource "google_project_iam_member" "pubsub_role" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:pubsub-push-sa@kubernetes-cost-project.iam.gserviceaccount.com"
}
#-------------------------
#  Cloud Run Service
# -------------------------
resource "google_service_account" "scaler_sa" {
  account_id   = "scaler-sa"
  display_name = "Cloud Run Scaler Service Account"
  project      = var.project_id
}

resource "google_project_iam_binding" "scaler_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.scaler_sa.email}"
  ]
}
###################################
# Alert Forwarder Cloud Run
###################################

resource "google_cloud_run_service" "alert_forwarder" {
  name     = "alert-forwarder"
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.scaler_sa.email # Use the same service account as the Scaler


      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/my-repo/alert-forwarder:latest"
        # ^-- see below on building/pushing Docker image
        ports {
          container_port = 8080
        }
        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.scale_alerts_topic.name
        }
        env {
          name  = "SHARED_SECRET" # This is a secret that the Scaler will use to verify the Alert Forwarder's signature
          value = "MY_SHARED_SECRET" # Change this to a secret value in production
        }
      }
    }
  }

  # Allow unauthenticated invocations (since Alertmanager can't do OIDC)
  traffic {
    percent         = 100
    latest_revision = true
  }
}
###################################
# Scaler Cloud Run
###################################
resource "google_cloud_run_service" "scaler" {
  name     = "scaler"
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.scaler_sa.email # Use the same service account as the Alert Forwarder

      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/my-repo/scaler:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "CLUSTER_LOCATION"
          value = var.region
        }
        env {
          name  = "CLUSTER_NAME"
          value = var.cluster_name
        }
      }
    }
  }

  # Do NOT allow unauthenticated. Only Pub/Sub can invoke it with OIDC token.
  traffic {
    percent         = 100
    latest_revision = true
  }
}

