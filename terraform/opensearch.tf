# OpenSearch Serverless collection to hold the vector index for the Knowledge Base.
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "rag-kb-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules       = [{ Resource = ["collection/rag-kb"], ResourceType = "collection" }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "rag-kb-network"
  type = "network"
  policy = jsonencode([{
    Rules = [
      { Resource = ["collection/rag-kb"], ResourceType = "collection" },
      { Resource = ["collection/rag-kb"], ResourceType = "dashboard" }
    ]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_collection" "kb" {
  name       = "rag-kb"
  type       = "VECTORSEARCH"
  depends_on = [aws_opensearchserverless_security_policy.encryption, aws_opensearchserverless_security_policy.network]
}
