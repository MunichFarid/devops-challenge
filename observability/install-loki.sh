#!/usr/bin/env bash
set -euo pipefail

# Add repo (once)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki stack into monitoring
helm upgrade --install loki grafana/loki-stack \
  -n monitoring \
  -f loki-values.yaml \
  --wait --timeout 10m

# Provision the Grafana datasource (picked up by the sidecar)
kubectl apply -f loki-datasource-cm.yaml
