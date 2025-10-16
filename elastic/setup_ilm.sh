#!/usr/bin/env bash
set -euo pipefail

ES_URL="${ES_URL:-http://localhost:9200}"
POLICY="${ILM_POLICY:-app-logs-ilm}"
ALIAS="${ILM_ALIAS:-app-logs}"
PATTERN="${ILM_PATTERN:-app-logs-000001}"

echo "📜 ILM policy: $POLICY"
curl -s -k -X PUT "$ES_URL/_ilm/policy/$POLICY" -H 'Content-Type: application/json' -d '{
  "policy": {
    "phases": {
      "hot": { "actions": { "rollover": { "max_size": "50mb", "max_age": "7d" } } },
      "delete": { "min_age": "30d", "actions": { "delete": {} } }
    }
  }
}' >/dev/null

echo "🧩 Template com alias/ILM"
curl -s -k -X PUT "$ES_URL/_index_template/${ALIAS}-template" -H 'Content-Type: application/json' -d "{
  \"index_patterns\": [\"${ALIAS}-*\"]
  , \"template\": {
    \"settings\": {
      \"index.lifecycle.name\": \"$POLICY\",
      \"index.lifecycle.rollover_alias\": \"$ALIAS\",
      \"number_of_shards\": 1,
      \"number_of_replicas\": 0
    },
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

echo "📦 Índice inicial: $PATTERN (alias: $ALIAS)"
curl -s -k -X PUT "$ES_URL/$PATTERN" -H 'Content-Type: application/json' -d "{
  \"aliases\": { \"$ALIAS\": { \"is_write_index\": true } }
}" >/dev/null || true
echo "✅ ILM pronto"
