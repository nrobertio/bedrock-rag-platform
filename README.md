# Bedrock RAG Platform

A production-shaped **Retrieval-Augmented Generation** stack on **Amazon Bedrock**: a Bedrock **Knowledge Base** backed by S3 and OpenSearch Serverless, a **Lambda + API Gateway** query API that calls RetrieveAndGenerate with Anthropic Claude, **least-privilege IAM** per component, and a **budget guardrail** that caps spend. Terraform for the infrastructure, Python for the API.

> Maintained by [nrobertio](https://github.com/nrobertio). A generic, public version of the production GenAI work I do: document-grounded assistants on Bedrock with the security and cost controls to run them for real, not as a demo.

## What this demonstrates

- **RAG on Bedrock**: a Knowledge Base (S3 data source + OpenSearch Serverless vector store) queried through RetrieveAndGenerate.
- **A real API**: API Gateway to a Python Lambda that answers questions with citations.
- **Security**: least-privilege IAM per role, no model access wider than needed, input size limits.
- **Cost control**: an AWS Budget alert so a runaway prompt loop cannot silently rack up spend.
- **Infrastructure as Code**: Terraform for everything, Python for the handler.

## How it works

```
User -> API Gateway -> Lambda (Python)
                          |
                          v
            Bedrock RetrieveAndGenerate
              |-- Knowledge Base (retrieve)
              |     |-- OpenSearch Serverless (vectors)
              |     |-- S3 (source documents)
              |-- Claude (generate grounded answer + citations)
```

## Layout

```
terraform/     Knowledge Base, OpenSearch Serverless, S3, IAM, API Gateway, Lambda, Budget
lambda/query/  Python handler calling bedrock-agent-runtime RetrieveAndGenerate
docs/PROJECT.md  why, how, benefits, interview notes
```

## Usage

```bash
cd terraform && terraform init && terraform apply
# upload documents to the KB data-source S3 bucket, then sync the Knowledge Base
curl -XPOST "$(terraform output -raw api_url)/ask" -d '{"question":"What is our refund policy?"}'
```

## Cost and safety note

Bedrock and OpenSearch Serverless are billed per use and per OCU; this is not free-tier. The included Budget alerts on spend. Destroy when finished. Never send secrets or personal data into prompts.

## License

MIT. See [LICENSE](LICENSE).
