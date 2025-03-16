terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.25.0"
    }
  }

  backend "local" {} # We'll update this later for remote state storage
}

provider "google" {
  credentials = file("terraform-key.json") # This points to our downloaded key
  project     = "YOUR_PROJECT_ID"
  region      = "us-central1"
}