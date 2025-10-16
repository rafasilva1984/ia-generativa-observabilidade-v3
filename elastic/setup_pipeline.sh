#!/usr/bin/env bash
set -euo pipefail
ES_URL="${ES_URL:-http://localhost:9200}"
PIPE_ID="${PIPE_ID:-logs-grok-pipeline}"
echo "🔧 Pipeline (grok)"
curl -s -k -X PUT "$ES_URL/_ingest/pipeline/$PIPE_ID" -H 'Content-Type: application/json' -d '{
  "processors": [{
    "grok": { "field": "message", "patterns": ["%{WORD:component} %{DATA:detail}"] }
  }]
}' >/dev/null
echo "✅ Pipeline criado: $PIPE_ID"
