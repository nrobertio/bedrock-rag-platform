# Project Writeup: Bedrock RAG Platform

Why this exists, how it was built, why each choice, and the benefits.

## 1. The problem it solves

A raw large language model answers from its training data: it cannot cite your documents, it goes stale, and it will confidently make things up. Retrieval-Augmented Generation (RAG) fixes this by retrieving relevant passages from your own content and grounding the model's answer in them, with citations. The hard part is not the demo, it is running it safely and affordably: least-privilege access, input limits, and a cost cap so a runaway loop cannot produce a surprise bill. This project builds a grounded question-answering API on Amazon Bedrock with those controls.

## 2. How it was built

Terraform for the infrastructure, Python for the API:

- storage: an S3 bucket (public access blocked) holding the source documents.
- opensearch: an OpenSearch Serverless vector collection with encryption and network policies.
- knowledge_base: a Bedrock Knowledge Base that embeds the S3 documents into the vector store, with an IAM role scoped to exactly that S3 bucket, the embedding model, and the collection.
- api: an API Gateway HTTP API to a Python Lambda that calls Bedrock RetrieveAndGenerate and returns the answer plus S3 citations.
- budget: an AWS Budget that alerts at 80 percent of a monthly cap.

The Terraform passes terraform validate; the handler is valid Python.

## 3. Why each choice

- Managed Knowledge Base over hand-rolled RAG: Bedrock handles chunking, embedding and retrieval, so there is less bespoke glue to maintain and it stays in one security boundary.
- OpenSearch Serverless as the vector store: no cluster to size or patch; it scales with usage. The trade-off is per-OCU cost, which is why the budget guardrail matters.
- RetrieveAndGenerate in one call: Bedrock retrieves and grounds the generation together and returns citations, so the API can show its sources rather than asking users to trust it.
- Least-privilege per role: the Knowledge Base role can read only its S3 bucket, invoke only the embedding model, and reach only its collection; the query Lambda can only call the Bedrock RAG actions and write logs.
- Input size limit and a budget: the two cheapest defenses against cost blow-ups, a capped question length and a spend alert.

## 4. Benefits

- Answers are grounded in your documents and come with citations, which cuts hallucination and builds trust.
- It stays current by re-syncing the Knowledge Base when documents change, no retraining.
- It is production-shaped, not a notebook: an API, IAM boundaries, and a cost guardrail.
- All infrastructure is code, reproducible and reviewable.

## 5. Design notes and trade-offs

- Why RAG over fine-tuning: RAG grounds answers in current, private data with citations and no training cost; fine-tuning changes style or format but does not keep facts fresh.
- What RetrieveAndGenerate does: retrieves top-k passages from the vector store and passes them as context to the model in one managed call, returning citations.
- How you keep GenAI costs predictable: capped input, a monthly budget alert, and awareness that OpenSearch Serverless bills per OCU.
- Security risks specific to LLM apps: prompt injection, data leakage and over-broad model access; here, least-privilege IAM and input limits are the first line, and you would add output filtering and prompt hardening next.
- What to add next: a Bedrock Agent for multi-step tasks, response guardrails (Bedrock Guardrails) for PII and toxicity, and per-user auth on the API.

## 6. How to run it

```bash
cd terraform
terraform init
terraform apply    # set kb_bucket_name and alert_email

# upload documents to the KB bucket, then sync the data source in the Bedrock console or via API
curl -XPOST "$(terraform output -raw api_url)/ask" -d '{"question":"..."}'
```

Bedrock and OpenSearch Serverless are billed per use and are not free-tier; the budget alerts on spend and terraform destroy tears it all down.