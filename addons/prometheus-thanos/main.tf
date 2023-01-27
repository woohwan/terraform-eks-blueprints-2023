
module "eks_blueprints_monitoring_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = data.aws_eks_cluster.eks_blueprints.id
  eks_cluster_endpoint = data.aws_eks_cluster.eks_blueprints.endpoint
  eks_oidc_provider    = local.cluster_oidc_provider
  eks_cluster_version  = data.aws_eks_cluster.eks_blueprints.version

  # Addons: Prometheus
  enable_kube_prometheus_stack = true
  kube_prometheus_stack_helm_config = {
    values = [templatefile("prometheus-values.yaml", {
      certificate_arn                       = var.certificate_arn,
      thanos_sidecar_role_arn               = module.iam_assumable_role_prometheus.iam_role_arn
      thanos_sidecar_objconfig_secret_name  =  var.thanos_sidecar_objstore_secrete_name
    })]
  }

  tags = local.tags
}