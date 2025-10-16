# Troubleshooting

- API `/health` mostra `elasticsearch:false`  
  → aguarde alguns segundos, os healthchecks mudam a ordem de inicialização, depois rode `bash elastic/ingest_data.sh`.

- Porta já em uso (9200/5601/8000/11435)  
  → edite mapeamentos em `docker-compose-bypass.yml`.

- Resposta rasa do LLM  
  → esse pacote usa `mock-llm` didático. Use o gerador de logs `elastic/generate_logs.py` para inserir mais dados e enriquecer a narrativa.

- Windows (Docker Desktop)  
  → rode em PowerShell como admin e confirme que o WSL2 está habilitado. Se usar antivírus corporativo, adicione a pasta do projeto como exceção.
