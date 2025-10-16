#!/usr/bin/env bash
set -euo pipefail
ES_URL="${ES_URL:-http://localhost:9200}"
ALIAS="${ILM_ALIAS:-app-logs}"
DATA_FILE="${DATA_FILE:-./elastic/logs-sample.jsonl}"
echo "📥 Ingestão via alias (ILM): $ALIAS"
TMP="$(mktemp)"
while IFS= read -r line; do
  echo '{ "index": { "_index": "'"$ALIAS"'" } }' >> "$TMP"
  echo "$line" >> "$TMP"
done < "$DATA_FILE"
curl -s -k -H 'Content-Type: application/x-ndjson' -X POST "$ES_URL/_bulk" --data-binary "@$TMP" >/dev/null
rm -f "$TMP"
curl -s -k "$ES_URL/$ALIAS*/_count"; echo
