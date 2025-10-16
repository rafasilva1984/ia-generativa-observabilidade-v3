.PHONY: up down ingest setup-ds ingest-ds setup-ilm ingest-ilm gen reset

up:
	docker compose -f docker-compose-bypass.yml up -d --build

down:
	docker compose -f docker-compose-bypass.yml down -v

ingest:
	bash ./elastic/ingest_data.sh

setup-ds:
	bash ./elastic/setup_data_stream.sh

ingest-ds:
	bash ./elastic/ingest_data_stream.sh

setup-ilm:
	bash ./elastic/setup_ilm.sh

ingest-ilm:
	bash ./elastic/ingest_ilm.sh

gen:
	python3 ./elastic/generate_logs.py 400 > /tmp/gen.jsonl && ES_URL=http://localhost:9200 INDEX=app-logs DATA_FILE=/tmp/gen.jsonl bash ./elastic/ingest_data.sh

reset: down up
