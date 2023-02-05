provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_blueprints.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_blueprints.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_blueprints.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_blueprints.token
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
  opensearch_arn = var.opensearch_arn
  opensearch_endpoint = var.opensearch_endpoint

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
  aws_for_fluentbit_irsa_policies = [aws_iam_policy.fluentbit_opensearch_access.arn]
  aws_for_fluentbit_helm_config = {
    name                = "aws-for-fluent-bit"
    chart               = "aws-for-fluent-bit"
    version             = "0.1.22"
    namespace           = "logging"
    create_namespace    = true
    values = [templatefile("${path.module}/helm_values/aws-for-fluentbit-values.yaml", {
      aws_region = local.region
      host       = local.opensearch_endpoint

    })]
  }

  tags = local.tags
}

resource "aws_iam_policy" "fluentbit_opensearch_access" {
  name        = "fluentbit_opensearch_access"
  description = "IAM policy to allow Fluentbit access to OpenSearch"
  policy      = data.aws_iam_policy_document.fluentbit_opensearch_access.json
}