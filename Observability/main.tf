provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_availability_zones" "available" {
  filter {
    name = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # name = basename(path.cwd)
  name = "eks_observability_accelerator"
  cluster_name = coalesce(var.cluster_name, local.name)
  region = "ap-northeast-2"

  # Avoid 10.0.0.0/16
  vpc_cidr = "10.1.0.0/16"
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint = local.name
    eks_observability_accelerator = "adot-amp-amg"
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

}

# Create EKS Cluster
module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.20.0"

  cluster_name = local.cluster_name
  cluster_version = "1.24"

  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      min_size        = 1
      subnet_ids      = module.vpc.private_subnets
    }
  }
  
  tags = local.tags
}


#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}


module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.20.0"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  # Other Addons
  enable_aws_load_balancer_controller = true
  enable_external_dns = true
  eks_cluster_domain  = "steve-aws.com"

  tags = local.tags
}



# module "eks_observability_accelerator" {
#   source = "github.com/aws-observability/terraform-aws-observability-accelerator?ref=v1.5.0"

#   aws_region = local.region
#   eks_cluster_id = module.eks_blueprints.eks_cluster_id

#   enable_amazon_eks_adot = true
  
#    # reusing existing Amazon Managed Prometheus Workspace
#   enable_managed_prometheus = false
#   managed_prometheus_workspace_id     = "ws-9953dc48-606f-4a85-ac53-4b7dec289572"
#   enable_alertmanager = true

#   enable_managed_grafana       = false
#   managed_grafana_workspace_id = "g-10f0411262"
#   # grafana_api_key              = var.grafana_api_key

#   tags = local.tags
# }

# module "workloads_infra" {
#   source = "github.com/aws-observability/terraform-aws-observability-accelerator/modules/workloads/infra"

#   eks_cluster_id = module.eks_observability_accelerator.eks_cluster_id

#   dashboards_folder_id = module.eks_observability_accelerator.grafana_dashboards_folder_id
#   managed_prometheus_workspace_id = module.eks_observability_accelerator.managed_prometheus_workspace_id

#   managed_prometheus_workspace_endpoint = module.eks_observability_accelerator.managed_prometheus_workspace_endpoint
#   managed_prometheus_workspace_region = module.eks_observability_accelerator.managed_prometheus_workspace_region
# }