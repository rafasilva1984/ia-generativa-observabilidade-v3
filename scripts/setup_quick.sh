#!/usr/bin/env bash
set -euo pipefail
echo "🚀 Subindo stack (bypass)..."
docker compose -f docker-compose-bypass.yml up -d --build
echo "⏳ Aguardando serviços ficarem saudáveis..."
sleep 10
echo "📥 Ingerindo dados de exemplo..."
bash ./elastic/ingest_data.sh
echo "✅ Pronto!"
echo "- Kibana: http://localhost:5601"
echo "- Swagger: http://localhost:8000/docs"
echo "- Mock LLM: http://localhost:11435/health"
