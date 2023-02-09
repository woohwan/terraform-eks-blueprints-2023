resource "null_resource" "role-mapping" {
  provisioner "local-exec" {
      command = <<EOT
        curl -sS -u ${var.opensearch_dashboard_user}:${var.opensearch_dashboard_pw} \
            -X PATCH \
            https://${aws_elasticsearch_domain.opensearch.endpoint}/_opendistro/_security/api/rolesmapping/all_access?pretty \
            -H 'Content-Type: application/json' \
            -d'
          [
            {
              "op": "add", "path": "/backend_roles", "value": ["${module.logging.aws_for_fluent_bit.irsa_arn}"]
            }
          ]
        '
EOT
  }
  depends_on = [
    aws_elasticsearch_domain.opensearch, module.logging
  ]
}