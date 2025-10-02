#!/usr/bin/env bash
mkdir -p ~/pg-data/orders
docker run -d --name orders-pg \
  -e POSTGRES_USER=orders_user \
  -e POSTGRES_PASSWORD=orders_pass \
  -e POSTGRES_DB=orders_db \
  -p 5432:5432 \
  -v ~/pg-data/orders:/var/lib/postgresql/data \
  --health-cmd='pg_isready -U orders_user -d orders_db' \
  --health-interval=10s --health-timeout=5s --health-retries=5 \
  postgres:16-alpine
