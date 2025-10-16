import os
from typing import Optional, Dict, Any
from fastapi import FastAPI
from pydantic import BaseModel
from elasticsearch import Elasticsearch
from dotenv import load_dotenv
from prompts import SYSTEM_PROMPT, USER_TEMPLATE
from llm_backends import generate_response

load_dotenv()

ELASTIC_URL = os.getenv("ELASTIC_URL", "http://elasticsearch:9200")
DEFAULT_TIME_RANGE = os.getenv("DEFAULT_TIME_RANGE", "now-24h")
DEFAULT_INDEX = os.getenv("DEFAULT_INDEX", "app-logs")
MAX_DOCS = int(os.getenv("MAX_DOCS", "30"))

es = Elasticsearch(ELASTIC_URL, verify_certs=False)

app = FastAPI(
    title="Observabilidade + IA Generativa (bypass)",
    description="Chat com Logs (RAG) local, sem HTTPS externo",
    version="1.3.0"
)

class QueryRequest(BaseModel):
    question: str
    index: Optional[str] = None
    time_range: Optional[str] = DEFAULT_TIME_RANGE
    size: Optional[int] = MAX_DOCS

def search_evidence(index: str, time_range: str, size: int):
    idx = index or DEFAULT_INDEX
    query = { "bool": { "filter": [ { "range": { "@timestamp": { "gte": time_range, "lte": "now" } } } ] } }
    resp = es.search(index=idx, query=query, sort=[{"@timestamp": "desc"}], size=size)
    hits = resp.get("hits", {}).get("hits", [])
    lines = []
    for h in hits:
        s = h.get("_source", {})
        lines.append(f"[{s.get('@timestamp')}] svc={s.get('service.name')} level={s.get('log.level')} code={s.get('http.response.status_code','')} latency_ms={s.get('latency_ms','')} msg={s.get('message')}")
    return "\n".join(lines[:size])

@app.get("/health")
def health():
    try:
        es_ok = es.ping()
    except Exception:
        es_ok = False
    return {"ok": True, "elasticsearch": es_ok, "default_index": DEFAULT_INDEX}

@app.post("/query")
def query_logs(req: QueryRequest):
    evidence = search_evidence(req.index or DEFAULT_INDEX, req.time_range, req.size)
    user_prompt = USER_TEMPLATE.format(question=req.question, evidence=evidence[:6000])
    answer = generate_response(SYSTEM_PROMPT, user_prompt)
    return { "question": req.question, "time_range": req.time_range, "target_index": req.index or DEFAULT_INDEX, "evidence_sample": evidence.splitlines()[:5], "answer": answer }

class SummaryRequest(BaseModel):
    index: Optional[str] = None
    time_range: Optional[str] = DEFAULT_TIME_RANGE
    service: Optional[str] = None
    size: Optional[int] = MAX_DOCS

def build_summary(index: str, time_range: str, service: Optional[str], size: int) -> Dict[str, Any]:
    idx = index or DEFAULT_INDEX
    must_filters = [ { "range": { "@timestamp": { "gte": time_range, "lte": "now" } } } ]
    if service:
        must_filters.append({ "term": { "service.name": service } })
    query = { "bool": { "filter": must_filters } }
    resp = es.search(index=idx, query=query, size=size, sort=[{"@timestamp": "desc"}], aggs={
        "by_service": { "terms": { "field": "service.name", "size": 10 } },
        "by_status":  { "terms": { "field": "http.response.status_code", "size": 10 } },
        "levels":     { "terms": { "field": "log.level", "size": 10 } }
    })
    hits = resp.get("hits", {}).get("hits", [])
    sample = []
    for h in hits[:10]:
        s = h.get("_source", {})
        sample.append(f"{s.get('@timestamp')} {s.get('service.name')} {s.get('log.level')} {s.get('http.response.status_code','')} {s.get('message')}")
    return {
        "total": resp.get("hits", {}).get("total", {}).get("value", 0),
        "services": [b["key"] for b in resp["aggregations"]["by_service"]["buckets"]],
        "status_top": [int(b["key"]) for b in resp["aggregations"]["by_status"]["buckets"] if b.get("key") is not None],
        "levels": [b["key"] for b in resp["aggregations"]["levels"]["buckets"]],
        "sample": sample
    }

@app.post("/incident/summary")
def incident_summary(req: SummaryRequest):
    meta = build_summary(req.index, req.time_range, req.service, req.size)
    question = f"Produza um resumo de incidente para o período {req.time_range} até agora"
    if req.service:
        question += f" focado no serviço {req.service}"
    evidence = "\n".join(meta.get("sample", []))
    user_prompt = f"""{question}.
Dados agregados:
- total de eventos: {meta.get('total')}
- serviços mais citados: {', '.join(meta.get('services', [])[:5])}
- status codes frequentes: {', '.join(map(str, meta.get('status_top', [])[:5]))}
- níveis de log: {', '.join(meta.get('levels', [])[:5])}

Evidências (amostras):
{evidence}
"""
    answer = generate_response(SYSTEM_PROMPT, user_prompt)
    return { "index": req.index or DEFAULT_INDEX, "meta": meta, "summary": answer }

@app.get("/")
def root():
    return {"message": "Use /docs (Swagger). Endpoints: /health, /query, /incident/summary"}
