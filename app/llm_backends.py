import os, httpx

USE_OLLAMA = os.getenv("USE_OLLAMA", "false").lower() == "true"
MOCK_LLM_URL = os.getenv("MOCK_LLM_URL", "http://mock-llm:11435")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

def generate_response(system_prompt: str, user_prompt: str) -> str:
    # Bypass mode: prioritize local mock
    if OPENAI_API_KEY:
        return "[OPENAI desativado neste pacote bypass (didático)]"
    try:
        payload = {"messages": [{"role": "system", "content": system_prompt},
                                {"role": "user", "content": user_prompt}]}
        with httpx.Client(timeout=20.0) as client:
            r = client.post(f"{MOCK_LLM_URL}/v1/chat", json=payload)
            r.raise_for_status()
            data = r.json()
            return data.get("choices", [{}])[0].get("message", {}).get("content", "[MOCK_EMPTY]")
    except Exception as e:
        return f"[MOCK ERROR] {e}"
