#!/usr/bin/env bash
set -euo pipefail

CLUSTER="kind-kind"
NAMESPACE="monitoring"
RELEASE="kps"
CHART="prometheus-community/kube-prometheus-stack"
HELM_TIMEOUT="20m"
VALUES_FILE="./values-kind.yaml"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; }; }
need kubectl; need helm; need jq; need openssl

# Ensure context
if ! kubectl config current-context | grep -q "^${CLUSTER}\$"; then
  kubectl config use-context "$CLUSTER" >/dev/null
fi

echo "[1/3] Create namespace if needed"
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "[2/3] Create fixed Grafana admin credentials"
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="P@ssword"
SECRET_NAME="${RELEASE}-grafana-admin"
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=admin-user="$GRAFANA_ADMIN_USER" \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[3/3] Install kube-prometheus-stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null 2>&1 || true

echo "Uninstalling existing release (ok if missing)..."
helm uninstall "$RELEASE" -n "$NAMESPACE" --wait --timeout 20s || true

helm upgrade --install "$RELEASE" "$CHART" \
  -n "$NAMESPACE" \
  -f "$VALUES_FILE" \
  --wait \
  --timeout "$HELM_TIMEOUT"

echo
echo "=== Prometheus + Grafana installed on kind ==="
echo "Grafana:    http://grafana.localtest.me  (user: $GRAFANA_ADMIN_USER)"
echo "Prometheus: http://prometheus.localtest.me"
echo "$GRAFANA_ADMIN_PASSWORD" > ./grafana-admin.pass
echo "Saved admin password to ./grafana-admin.pass"
echo
echo "If names don’t resolve, add to /etc/hosts -> 127.0.0.1 grafana.localtest.me prometheus.localtest.me"
echo "Uninstall: helm uninstall $RELEASE -n $NAMESPACE"
