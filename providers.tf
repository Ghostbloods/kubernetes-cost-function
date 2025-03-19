terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.25.0"
    }
  }

  backend "local" {} # We'll update this later for remote state storage
}
