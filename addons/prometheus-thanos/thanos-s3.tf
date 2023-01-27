# Prometheus
# resource "kubernetes_namespace" "prometheus" {
#   metadata {
#     name = var.kube_prometheus_namespace
#   }
# }


# create S3 bucket for thanos store
resource "aws_s3_bucket" "thanos" {
  bucket = "${local.cluster_name}-thanos"
  tags = {
    "Blueprints" = local.cluster_name
  }
}

# create IAM Policy for thanos sidecar
resource "aws_iam_policy" "thanos_sidecar" {
  name_prefix = "thanos_sidecar-"
  description = "policy for thanos sidecar in project osung-mart"
  policy = data.aws_iam_policy_document.thanos_sidecar.json
}

data "aws_iam_policy_document" "thanos_sidecar" {
  statement {
    sid = "thanosSicdecarS3"
    effect = "Allow"
    actions = [ 
      "s3:ListBuckt",
      "s3:GetObject" ,
      "s3:PutObject",
      "s3:DeleteObject"
      ]
    resources = [
      "${aws_s3_bucket.thanos.arn}",
      "${aws_s3_bucket.thanos.arn}/*"
    ]
  }
}

# cdreate IAM Role for thanos sidecar (prometheus)
module "iam_assumable_role_prometheus" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~>5.11.1"
  create_role                   = true
  role_name                     = "thanos-sidecar"
  provider_url                  = local.cluster_oidc_provider
  role_policy_arns              = [aws_iam_policy.thanos_sidecar.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.kube_prometheus_namespace}:${local.kube_prometheus_sa}"]
}

# module "prometheus-irsa" {
#   source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/irsa"
  
#   create_kubernetes_namespace = false
#   create_kubernetes_service_account = false
#   eks_cluster_id = local.name
#   eks_oidc_provider_arn = "arn:aws:iam:::oidc-provider/${local.cluster_oidc_provider}"
#   irsa_iam_policies = [aws_iam_policy.thanos_sidecar.arn]
#   irsa_iam_role_name = "thanos-sidecar"
#   kubernetes_namespace = var.kube_prometheus_namespace
#   kubernetes_service_account = var.kube_prometheus_sa

#   depends_on = [
#     module.eks_blueprints_kubernetes_addons
#   ]
# }

# Thnanos sidecar storage
resource "kubernetes_secret_v1" "prometheus_object_store_config" {
  metadata {
    name = var.thanos_sidecar_objstore_secrete_name
    namespace = var.kube_prometheus_namespace
  }

  data = {
    "thanos.yaml" = yamlencode({
      type = "s3"
      config = {
        bucket = aws_s3_bucket.thanos.bucket
        endpoint = replace(aws_s3_bucket.thanos.bucket_regional_domain_name, "${aws_s3_bucket.thanos.bucket}.","")
      }
    })
  }

  depends_on = [
    module.eks_blueprints_monitoring_addons
  ]
}