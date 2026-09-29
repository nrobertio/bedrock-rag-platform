# RAG query API handler.
# Receives {"question": "..."} and answers with a grounded response plus
# citations using Bedrock RetrieveAndGenerate against the Knowledge Base.
import json
import os

import boto3

KB_ID = os.environ["KNOWLEDGE_BASE_ID"]
MODEL_ID = os.environ["GENERATION_MODEL_ID"]
MAX_QUESTION_CHARS = 2000

agent = boto3.client("bedrock-agent-runtime")


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "invalid JSON body"})

    question = (payload.get("question") or "").strip()
    if not question:
        return _response(400, {"error": "field 'question' is required"})
    if len(question) > MAX_QUESTION_CHARS:
        return _response(413, {"error": "question too long"})

    region = boto3.session.Session().region_name
    model_arn = "arn:aws:bedrock:" + region + "::foundation-model/" + MODEL_ID

    result = agent.retrieve_and_generate(
        input={"text": question},
        retrieveAndGenerateConfiguration={
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "knowledgeBaseId": KB_ID,
                "modelArn": model_arn,
            },
        },
    )

    answer = result.get("output", {}).get("text", "")
    citations = []
    for c in result.get("citations", []):
        for ref in c.get("retrievedReferences", []):
            loc = ref.get("location", {}).get("s3Location", {}).get("uri")
            if loc:
                citations.append(loc)

    return _response(200, {"answer": answer, "citations": sorted(set(citations))})
