#!/usr/bin/env bash
set -euo pipefail
ES_URL="${ES_URL:-http://localhost:9200}"
DS_NAME="${DS_NAME:-logs-app}"
DATA_FILE="${DATA_FILE:-./elastic/logs-sample.jsonl}"

echo "📥 Ingestão no Data Stream: $DS_NAME"
TMP="$(mktemp)"
while IFS= read -r line; do
  echo '{ "create": { "_index": "'"$DS_NAME"'" } }' >> "$TMP"
  echo "$line" >> "$TMP"
done < "$DATA_FILE"
curl -s -k -H 'Content-Type: application/x-ndjson' -X POST "$ES_URL/_bulk" --data-binary "@$TMP" >/dev/null
rm -f "$TMP"
curl -s -k "$ES_URL/$DS_NAME/_count"; echo
