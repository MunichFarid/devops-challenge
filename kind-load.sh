#!/usr/bin/env bash
set -euo pipefail
DIGEST=$(docker manifest inspect ghcr.io/munichfarid/fastapi-test:latest \
  | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest' | head -n1)

echo "$DIGEST"
docker pull ghcr.io/munichfarid/fastapi-test@${DIGEST}
docker tag ghcr.io/munichfarid/fastapi-test@${DIGEST} ghcr.io/munichfarid/fastapi-test:amd64-latest
kind load docker-image ghcr.io/munichfarid/fastapi-test:amd64-latest --name kind
