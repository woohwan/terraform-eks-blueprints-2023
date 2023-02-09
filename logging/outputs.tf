output "irsa_arn" {
  value = module.logging.aws_for_fluent_bit.irsa_arn
}

output "irsa_name" {
  value = module.logging.aws_for_fluent_bit.irsa_name
}

output "opensearch_endpoint" {
  value = aws_elasticsearch_domain.opensearch.endpoint
}

output "opensearch_kibana_endpoint" {
  value = aws_elasticsearch_domain.opensearch.kibana_endpoint
}