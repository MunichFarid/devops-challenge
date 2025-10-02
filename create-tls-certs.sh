#!/usr/bin/env bash
set -euo pipefail

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout orders.key -out orders.crt \
  -subj "/CN=orders.localtest.me"

kubectl create secret tls orders-tls \
  --cert=orders.crt --key=orders.key

