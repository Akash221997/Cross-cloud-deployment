terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.70.0"
    }
  }

  required_version = ">= 0.14"
}

provider "aws" {
  region = var.aws_region
  profile = var.profile_name
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file(var.auth_file)
}
