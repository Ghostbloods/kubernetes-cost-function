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
  disk_size_gb     = 30  # Limit of 400 gb total for free tier
  machine_type     = var.machine_type
  preemptible      = true
  service_account  = "terraform-sa@${var.project_id}.iam.gserviceaccount.com" # Use the service account created earlier

  oauth_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}
}
