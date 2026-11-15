#!/usr/bin/env bash
set -euo pipefail
project=$1
expected=$2
cid=$(docker ps -q --filter "label=com.docker.compose.project=$project" --filter "label=com.docker.compose.service=web")
for i in $(seq 1 30); do
 if docker exec "$cid" python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/ready')" ; then break; fi
 sleep 1
done
docker exec "$cid" python -c "import urllib.request,json; d=json.load(urllib.request.urlopen('http://localhost:5000/api/info')); assert d['version']=='$expected',d; print(d)"
