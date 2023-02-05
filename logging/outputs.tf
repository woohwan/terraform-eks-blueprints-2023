output "irsa_arn" {
  value = module.logging.aws_for_fluent_bit.irsa_arn
}

output "irsa_name" {
  value = module.logging.aws_for_fluent_bit.irsa_name
}