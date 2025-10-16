from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any

app = FastAPI(title="Mock LLM", version="0.2")

class Msg(BaseModel):
    role: str
    content: str

class ChatReq(BaseModel):
    messages: List[Msg]

@app.get("/health")
def health():
    return {"ok": True, "mock": True}

@app.post("/v1/chat")
def chat(payload: ChatReq) -> Dict[str, Any]:
    user = next((m.content for m in payload.messages if m.role == "user"), "")
    # Gera um texto determinístico, mas útil para demo
    base = "[MOCK LLM] Resumo automático a partir das evidências.
"
    if "500" in user or "erro" in user.lower():
        extra = "Observação: picos de 500 em 'checkout'. Hipótese: pool de DB exaurido ou dependência externa lenta.
Ação: revisar conexões, limites e timeouts."
    else:
        extra = "Sem anomalias críticas na amostra. Continuar monitoramento e validar SLOs."
    content = base + extra
    return {"choices":[{"message":{"role":"assistant","content":content}}]}
