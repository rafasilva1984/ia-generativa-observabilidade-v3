#!/usr/bin/env bash
set -euo pipefail
ES_URL="${ES_URL:-http://localhost:9200}"
INDEX="${INDEX:-app-logs}"
DATA_FILE="${DATA_FILE:-./elastic/logs-sample.jsonl}"

echo "🔧 Criando índice: $INDEX"
curl -s -k -X PUT "$ES_URL/$INDEX" -H 'Content-Type: application/json' -d '{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": {
    "properties": {
      "@timestamp": {"type": "date"},
      "service.name": {"type": "keyword"},
      "log.level": {"type": "keyword"},
      "message": {"type": "text"},
      "http.response.status_code": {"type": "integer"},
      "latency_ms": {"type": "integer"}
    }
  }
}' >/dev/null || true

echo "📥 Ingerindo documentos (bulk)..."
TMP="$(mktemp)"
while IFS= read -r line; do
  echo '{ "index": { "_index": "'"$INDEX"'" } }' >> "$TMP"
  echo "$line" >> "$TMP"
done < "$DATA_FILE"

curl -s -k -H 'Content-Type: application/x-ndjson' -X POST "$ES_URL/_bulk" --data-binary "@$TMP" >/dev/null
rm -f "$TMP"

echo "✅ Concluído. Docs no índice $INDEX:"
curl -s -k "$ES_URL/$INDEX/_count"
echo
