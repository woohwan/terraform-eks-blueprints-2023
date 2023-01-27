variable "certificate_arn" {
  type = string
}

variable "kube_prometheus_namespace" {
  type = string
}

variable "kube_thanos_namespace" {
  type = string
}

variable "kube_prometheus_sa" {
  type = string
}

variable "thanos_sidecar_objstore_secrete_name" {
  type = string
}