# Arquitetura (BYPASS LAB - Max)

```
Elasticsearch <-- FastAPI (RAG) --> Mock LLM (local)
      ^             ^
      |             |
   Kibana       Postman/Swagger

[Ingestão] -> Índice clássico (app-logs) OU Data Stream (logs-app) OU ILM (app-logs-*)
```
