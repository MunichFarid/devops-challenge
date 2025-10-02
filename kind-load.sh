#!/usr/bin/env bash
set -euo pipefail
DIGEST=$(docker manifest inspect ghcr.io/munichfarid/devops-challenge:latest \
  | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest' | head -n1)

echo "$DIGEST"
docker pull ghcr.io/munichfarid/devops-challenge@${DIGEST}
docker tag ghcr.io/munichfarid/devops-challenge@${DIGEST} ghcr.io/munichfarid/devops-challenge:amd64-latest
kind load docker-image ghcr.io/munichfarid/devops-challenge:amd64-latest --name kind
