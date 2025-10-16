#!/usr/bin/env python3
import json, random, sys
from datetime import datetime, timedelta, timezone

services = ["checkout","auth","catalog","payments","search","inventory"]
levels = ["INFO","WARN","ERROR"]
msgs = [
  "Timeout contacting auth API",
  "DB pool exhausted",
  "Third-party gateway timeout",
  "Cache warm complete",
  "Payment gateway declined",
  "JWT signature invalid",
  "Increased GC pause detected",
  "Queue length high",
  "Retrying downstream request"
]
def gen(n=200, start_minutes=120):
  now = datetime.now(timezone.utc)
  base = now - timedelta(minutes=start_minutes)
  for i in range(n):
    ts = base + timedelta(seconds=i*random.randint(1,6))
    yield {
      "@timestamp": ts.isoformat(),
      "service.name": random.choice(services),
      "log.level": random.choices(levels, weights=[0.6,0.25,0.15])[0],
      "message": random.choice(msgs),
      "http.response.status_code": random.choice([200,200,200,500,500,504,401,429]),
      "latency_ms": random.randint(20, 2500)
    }
if __name__ == "__main__":
  n = int(sys.argv[1]) if len(sys.argv)>1 else 200
  for d in gen(n):
    print(json.dumps(d))
