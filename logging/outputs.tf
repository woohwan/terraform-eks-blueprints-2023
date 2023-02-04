output "irsa_arn" {
  value = module.monitoring.aws_for_fluent_bit.irsa_arn
}

output "irsa_name" {
  value = module.monitoring.aws_for_fluent_bit.irsa_name
}