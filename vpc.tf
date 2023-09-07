# AWS VPC
module "vpc" {
  count = var.cloud_provider == "aws" ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.availability_zone
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "staging"
  }
}

# GCP VPC


module "gcp-network" {
    count = var.cloud_provider == "gcp" ? 1 : 0
    source  = "terraform-google-modules/network/google"
    version = "7.0.0"

    project_id   = var.project_id
    network_name = "vpc-${var.cluster_name}"
    auto_create_subnetworks = false
    subnets = [
        {
            subnet_name           = var.subnet
            subnet_ip             = "10.10.0.0/16"
            subnet_region         = var.region
        },
]

secondary_ranges = {
    (var.subnet) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}
