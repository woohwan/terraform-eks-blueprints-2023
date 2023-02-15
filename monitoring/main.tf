# provider "aws" {
#   region = local.region
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks_blueprints.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
#   # token                  = data.aws_eks_cluster_auth.eks_blueprints.token
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.eks_blueprints.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_blueprints.certificate_authority[0].data)
#     # token                  = data.aws_eks_cluster_auth.eks_blueprints.token
#     exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
#     command     = "aws"
#   }
#   }
# }

# module "monitoring" {
#   source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

#   eks_cluster_id       = data.aws_eks_cluster.eks_blueprints.id
#   eks_cluster_endpoint = data.aws_eks_cluster.eks_blueprints.endpoint
#   // issuer url에서  https:// 제거
#   eks_oidc_provider    = replace(data.aws_eks_cluster.eks_blueprints.identity[0].oidc[0].issuer, "https://", "")
#   eks_cluster_version  = data.aws_eks_cluster.eks_blueprints.version

#   # monitoring
#   eenable_kube_prometheus_stack      = true

#   kube_prometheus_stack_helm_config = {
#     set = [
#       {
#         name  = "kubeProxy.enabled"
#         value = false
#       }
#     ],
#     set_sensitive = [
#       {
#         name  = "grafana.adminPassword"
#         value = data.aws_secretsmanager_secret_version.admin_password_version.secret_string
#       }
#     ]
#   }

#   tags = local.tags
# }


# # Thanos (컴포넌트+사이드카)에 부여할 IAM Role
# resource "aws_iam_role" "thanos" {
#   name_prefix        = substr("${local.cluster_name}-thanos-", 0, 37)
#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "${module.eks_blueprints.eks_oidc_provider_arn}"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity"
#     }
#   ]
# }
# POLICY
#   inline_policy {
#     name = "s3-access"

#     policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:ListBucket",
#         "s3:GetObject",
#         "s3:DeleteObject",
#         "s3:PutObject"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.thanos.arn}",
#         "${aws_s3_bucket.thanos.arn}/*"
#       ]
#     }
#   ]
# }
# EOF
#   }
# }

