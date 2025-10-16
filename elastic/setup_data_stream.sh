#!/usr/bin/env bash
set -euo pipefail

ES_URL="${ES_URL:-http://localhost:9200}"
DS_NAME="${DS_NAME:-logs-app}"
RETENTION="${RETENTION:-30d}"

echo "🧩 Criando Data Stream Template: $DS_NAME"
curl -s -k -X PUT "$ES_URL/_index_template/${DS_NAME}-template" -H 'Content-Type: application/json' -d "{
  \"index_patterns\": [\"${DS_NAME}\"],
  \"data_stream\": {},
  \"template\": {
    \"settings\": { \"number_of_shards\": 1, \"number_of_replicas\": 0 },
    \"mappings\": {
      \"properties\": {
        \"@timestamp\": {\"type\": \"date\"},
        \"service.name\": {\"type\": \"keyword\"},
        \"log.level\": {\"type\": \"keyword\"},
        \"message\": {\"type\": \"text\"},
        \"http.response.status_code\": {\"type\": \"integer\"},
        \"latency_ms\": {\"type\": \"integer\"}
      }
    }
  }
}" >/dev/null

echo "🧪 Criando Data Stream: $DS_NAME"
curl -s -k -X PUT "$ES_URL/_data_stream/$DS_NAME" >/dev/null || true

echo "⏳ Lifecycle (retenção=$RETENTION)"
curl -s -k -X PUT "$ES_URL/_data_stream/$DS_NAME/_lifecycle" -H 'Content-Type: application/json' -d "{
  \"data_retention\": \"$RETENTION\"
}" >/dev/null || true

echo "✅ OK"
