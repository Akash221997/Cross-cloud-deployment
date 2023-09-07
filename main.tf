terraform {
 backend "gcs" {
      bucket = "akash-test-bucket-terraform"
  }
}


# AWS EKS cluster provision


module "eks" {
  count = var.cloud_provider == "aws" ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc[count.index].vpc_id
  subnet_ids = module.vpc[count.index].private_subnets

  #enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 10
  }

  eks_managed_node_groups = {
    general = {
      desired_size = 2
      min_size     = 2
      max_size     = 10

      labels = {
        role = "general"
      }

      instance_types = ["t2.micro"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "staging"
  }
}



# GCP GKE cluster provision



module "cloud-router" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  source  = "terraform-google-modules/cloud-router/google"
  version = "5.0.1"
  name    = "router-${var.cluster_name}"
  project = var.project_id
  region  = var.region
  network = module.gcp-network[count.index].network_name
}


module "cloud-nat" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "4.0.0"
  project_id                         = var.project_id
  region                             = var.region
  router                             = module.cloud-router[count.index].router.name
  name                               = "nat-${var.cluster_name}"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


module "gke" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                    = "26.1.1"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  network                    = module.gcp-network[count.index].network_name
  subnetwork                 = module.gcp-network[count.index].subnets_names[0]
  ip_range_pods              = var.ip_range_pods_name
  ip_range_services          = var.ip_range_services_name
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  #enable_private_endpoint    = true
  enable_private_nodes       = true
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks_config
  master_global_access_enabled = true
  initial_node_count           = 0
  remove_default_node_pool     = true
  kubernetes_version          = "latest"
  create_service_account      = false

  node_pools = [
    {
      name                      = "custom-node-pool"
      machine_type              = var.machine_type
      node_locations            = "us-central1-b,us-central1-c"
      min_count                 = 1
      max_count                 = 2
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 10
      disk_type                 = "pd-standard"
      image_type                = var.image_type
      enable_gcfs               = false
      enable_gvnic              = false
      autoscaling               = true
      auto_repair               = true
      auto_upgrade              = true
      service_account           = var.service_account
      preemptible               = false
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  node_pools_labels = {
    all = {}
  }
}
