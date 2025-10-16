# Observabilidade na Prática — IA Generativa (BYPASS LAB - Max)

> **Propósito:** laboratório **100% local** para demonstrar **IA Generativa aplicada à Observabilidade** — sem dependência de CA/SSL/HTTPS externos.
> Todos os downloads são evitados, e as integrações de IA são simuladas por um **Mock LLM** local.

## 🔧 Stack
- **Elasticsearch 8.15.2** — armazenamento e busca de logs
- **Kibana 8.15.2** — visualização e exploração
- **FastAPI (app)** — endpoints `/health`, `/query`, `/incident/summary`
- **Mock LLM (FastAPI)** — simula respostas do modelo (RAG didático, sem custo/HTTPS)

## 🚀 Subir em 3 passos
```bash
cp .env.example .env
docker compose -f docker-compose-bypass.yml up -d --build
bash ./elastic/ingest_data.sh
```
Acesse: Kibana http://localhost:5601 • Swagger http://localhost:8000/docs • Mock LLM http://localhost:11435/health

## 🧪 Modos de ingestão
1. **Índice clássico** (`app-logs`) — `bash ./elastic/ingest_data.sh`
2. **Data Stream + Lifecycle** (`logs-app`) —
   ```bash
   bash ./elastic/setup_data_stream.sh
   bash ./elastic/ingest_data_stream.sh
   ```
3. **ILM (rollover)** (`app-logs-*` com alias `app-logs`) —
   ```bash
   bash ./elastic/setup_ilm.sh
   bash ./elastic/ingest_ilm.sh
   ```

## 🧠 API — principais endpoints
- `GET /health` → ping ES + índice padrão
- `POST /query` → pergunta em LN (RAG simples com evidências)
- `POST /incident/summary` → resumo automático por janela/serviço (agregações + mock LLM)

Exemplo `/query`:
```json
{"question":"Explique os erros 500 nas últimas 2h","time_range":"now-2h","size":30}
```
Exemplo `/incident/summary`:
```json
{"time_range":"now-2h","service":"checkout","size":50}
```

## 🛠️ Makefile & scripts
- `make up` / `make down` / `make ingest`
- `bash scripts/setup_quick.sh` — sobe stack + ingere exemplo + imprime endpoints
- Gerador de logs: `python3 elastic/generate_logs.py 400 > /tmp/gen.jsonl && ES_URL=http://localhost:9200 INDEX=app-logs DATA_FILE=/tmp/gen.jsonl bash elastic/ingest_data.sh`

## 📦 Postman
Importe `postman/ObsNaPratica_bypass_max.postman_collection.json` e teste os endpoints.

## 🔐 Segurança (didático)
- **Bypass SSL** por padrão (`verify_certs=False`, `curl -k`).  
- **Não utilizar em produção.** Em ambiente real: TLS/SSL, autenticação, RBAC, PII masking e auditoria de prompts/respostas.

## 🧭 Arquitetura e Docs
- `docs/ARCHITECTURE.md` — visão da arquitetura
- `docs/TROUBLESHOOTING.md` — guia de resolução de problemas
- `docs/teleprompter_v3.html` — roteiro “Observabilidade na Prática”

## ⚠️ Observações
- Este pacote evita qualquer chamada HTTPS externa durante o *bring-up*.
- O **Mock LLM** foi feito para ensino: respostas são determinísticas e rápidas, com estrutura similar a uma IA real.
- Quando quiser demonstrar IA real (OpenAI/Ollama), use outro compose e remova o modo bypass.

---
**Licença:** MIT (didático). © Observabilidade na Prática.
