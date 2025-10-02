# ---- Builder stage ----
FROM python:3.13-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Build tools only for wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies into a portable venv layer
COPY requirements.txt .
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --upgrade pip setuptools wheel \
 && /opt/venv/bin/pip install -r requirements.txt

# ---- Runtime stage (non-root, minimal) ----
FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8000 \
    WORKERS=2

# Create non-root user with fixed UID/GID
RUN addgroup --system --gid 10001 app \
 && adduser --system --uid 10001 --ingroup app --home /home/app app

WORKDIR /app

# Copy the prebuilt virtualenv
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY --chown=app:app app app

# Drop privileges
USER 10001:10001

# Documented port
EXPOSE 8000

# HEALTHCHECK using python -c (no heredoc)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD python -c "import json,urllib.request,sys; r=urllib.request.urlopen('http://127.0.0.1:8000/health',timeout=2); sys.exit(0 if json.loads(r.read().decode()).get('status')=='ok' else 1)" || exit 1

# Build-time metadata
ARG VERSION=dev
ARG VCS_REF=unknown

# OCI labels (split to avoid quoting issues)
LABEL org.opencontainers.image.title="orders-api"
LABEL org.opencontainers.image.description="FastAPI Orders service (health, orders, minimal UI)"
LABEL org.opencontainers.image.version="$VERSION"
LABEL org.opencontainers.image.revision="$VCS_REF"

# Start app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
