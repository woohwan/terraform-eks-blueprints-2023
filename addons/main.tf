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

  tags = {
    Blueprint = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = data.aws_eks_cluster.eks_blueprints.id
  eks_cluster_endpoint = data.aws_eks_cluster.eks_blueprints.endpoint
  // issuer url에서  https:// 제거
  eks_oidc_provider    = replace(data.aws_eks_cluster.eks_blueprints.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_version  = data.aws_eks_cluster.eks_blueprints.version

  # Other Addons
  # enable_cert_manager = true

  # cert_manager_domain_names = [ "steve-aws.com"]
  # cert_manager_install_letsencrypt_issuers = true
  # cert_manager_letsencrypt_email = "whpark@saltware.co.kr"

  enable_external_dns = true
  eks_cluster_domain = "steve-aws.com"

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_helm_config = {
    namespace                  = "kube-system"
    values = [templatefile("${path.module}/values/alb-values.yaml", {
      cluster_name = local.cluster_name
      aws_region = local.region
    })]
  }

  enable_cluster_autoscaler = true

  # cert-manager namespace  필요 <- cert-manager install 후에 설치 또는  apply 재실행
  # enable_cert_manager_csi_driver = true

  tags = local.tags
}

