variable "project_id" {
  description = "GCP_PROJECT_ID"
  type        = string
}

variable "region" {
  description = "GCP region for deployment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2 # Changed from 3 to 2 because of limit per region without requesting more. 
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "pub_sub_sa" {
  description = "Service account for Pub/Sub"
  type        = string

}

variable "terraform_sa" {
  description = "Service account for Terraform"
  type        = string
}

variable "scaler_sa" {
  type        = string
  description = "Scaler service account email"
}

