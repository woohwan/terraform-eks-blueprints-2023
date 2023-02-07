# # Configure the Elasticsearch provider
# provider "elasticsearch" {
#   url = "http://127.0.0.1:9200"
# }


# resource "elasticsearch_opensearch_roles_mapping" "master_user_arn" {

#   role_name     = "all_access"
#   description   = "fluentbit"
#   backend_roles = local.fluentbit_role_arn
#   hosts         = [aws_elasticsearch_domain.opensearch.endpoint]
#   # users         = try(each.value.users, [])

#   depends_on = [
#     aws_elasticsearch_domain.opensearch, module.logging
#   ]
# }