provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_blueprints.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
  # token                  = data.aws_eks_cluster_auth.eks_blueprints.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_blueprints.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
    # token                  = data.aws_eks_cluster_auth.eks_blueprints.token
    exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    command     = "aws"
  }
  }
}

data "aws_eks_cluster" "eks_blueprints" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks_blueprints" {
  name = local.cluster_name
}

locals {
  name = "blueprints-terraform"
  cluster_name = local.name
  region = "ap-northeast-2"
  fluentbit_role_arn = module.logging.aws_for_fluent_bit.irsa_arn

  opensearch_arn = aws_elasticsearch_domain.opensearch.arn
  opensearch_endpoint = aws_elasticsearch_domain.opensearch.endpoint

  tags = {
    Blueprint = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

}

module "logging" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = data.aws_eks_cluster.eks_blueprints.id
  eks_cluster_endpoint = data.aws_eks_cluster.eks_blueprints.endpoint
  // issuer url에서  https:// 제거
  eks_oidc_provider    = replace(data.aws_eks_cluster.eks_blueprints.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_version  = data.aws_eks_cluster.eks_blueprints.version

  # Logging
  enable_aws_for_fluentbit        = true
  # aws_for_fluentbit_create_cw_log_group = false
  aws_for_fluentbit_irsa_policies = [aws_iam_policy.fluentbit_opensearch_access.arn]
  aws_for_fluentbit_helm_config = {
    version    = "0.1.22"
    values = [templatefile("${path.module}/helm_values/aws-for-fluentbit-values.yaml", {
      aws_region = local.region
      host       = aws_elasticsearch_domain.opensearch.endpoint
    })]
  }

  tags = local.tags

  depends_on = [
    aws_elasticsearch_domain.opensearch
  ]
}


#---------------------------------------------------------------
# Provision OpenSearch and Allow Access
#---------------------------------------------------------------
#tfsec:ignore:aws-elastic-search-enable-domain-logging
resource "aws_elasticsearch_domain" "opensearch" {
  domain_name           = "blueprints"
  elasticsearch_version = "OpenSearch_2.3"

  cluster_config {
    instance_type          = "t3.small.elasticsearch"
    instance_count         = 1
    zone_awareness_enabled = false

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.opensearch_dashboard_user
      master_user_password = var.opensearch_dashboard_pw
    }
  }

  depends_on = [
    aws_iam_service_linked_role.blueprints
  ]

  tags = local.tags
}


resource "aws_iam_service_linked_role" "blueprints" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_iam_policy" "fluentbit_opensearch_access" {
  name        = "fluentbit_opensearch_access"
  description = "IAM policy to allow Fluentbit access to OpenSearch"
  policy      = data.aws_iam_policy_document.fluentbit_opensearch_access.json
}

resource "aws_elasticsearch_domain_policy" "opensearch_access_policy" {
  domain_name     = aws_elasticsearch_domain.opensearch.domain_name
  access_policies = data.aws_iam_policy_document.opensearch_access_policy.json
}

# resource "aws_security_group" "opensearch_access" {
#   vpc_id      = module.vpc.vpc_id
#   description = "OpenSearch access"

#   ingress {
#     description = "host access to OpenSearch"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     self        = true
#   }

#   ingress {
#     description = "allow instances in the VPC (like EKS) to communicate with OpenSearch"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"

#     cidr_blocks = [module.vpc.vpc_cidr_block]
#   }

#   egress {
#     description = "Allow all outbound access"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
#   }

#   tags = local.tags
# }