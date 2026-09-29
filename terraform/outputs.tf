output "api_url" { value = aws_apigatewayv2_api.http.api_endpoint }
output "knowledge_base_id" { value = aws_bedrockagent_knowledge_base.this.id }
output "kb_bucket" { value = aws_s3_bucket.kb.id }
