variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "kb_bucket_name" {
  description = "S3 bucket holding the Knowledge Base source documents (globally unique)."
  type        = string
}

variable "embedding_model_arn" {
  description = "Bedrock embedding model ARN for the Knowledge Base."
  type        = string
  default     = "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-embed-text-v2:0"
}

variable "generation_model_id" {
  description = "Bedrock model id used by RetrieveAndGenerate."
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "monthly_budget" {
  type    = number
  default = 100
}

variable "alert_email" {
  type = string
}
