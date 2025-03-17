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
resource "google_pubsub_topic" "scale_alerts" {
  name    = "scale-alerts-topic"
  project = var.project_id

}
resource "google_pubsub_subscription" "scale_alerts_sub" {
  name    = "scale-alerts-sub"
  topic   = google_pubsub_topic.scale_alerts.name
  project = var.project_id

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = "https://us-central1-${var.project_id}.cloudfunctions.net/scale-alerts" # This is the URL of the Cloud Function we'll create later
    oidc_token {
      service_account_email = "terraform-sa@kubernetes-cost-project.iam.gserviceaccount.com" # Use the service account created earlier
    }
  }
}

resource "google_service_account" "pubsub_sa" {
  account_id   = "pubsub-sa"
  display_name = "Pub/Sub Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "pubsub_role" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:pubsub-sa@kubernetes-cost-project.iam.gserviceaccount.com"
}