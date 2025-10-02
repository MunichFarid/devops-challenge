from pprint import pformat
from fastapi.testclient import TestClient
from sqlalchemy import text
from app.main import app
from app.db import engine

client = TestClient(app)


def setup_module(_):
    print("\n[orders] ensuring table exists and truncating", flush=True)
    with engine.begin() as conn:
        conn.execute(
            text(
                """
            CREATE TABLE IF NOT EXISTS orders (
              id SERIAL PRIMARY KEY,
              amount NUMERIC(10,2) NOT NULL
            )
        """
            )
        )
        conn.execute(text("TRUNCATE TABLE orders RESTART IDENTITY"))
    print("[orders] table ready and empty", flush=True)


def test_create_order_and_list():
    payload = {"amount": "12.34"}
    print(f"\n[orders] POST /orders payload=\n{pformat(payload)}", flush=True)
    r = client.post("/orders", json=payload)
    print(f"[orders] POST status={r.status_code}", flush=True)
    try:
        print("[orders] POST body=\n" + pformat(r.json()), flush=True)
    except Exception:
        print("[orders] POST non-JSON body=\n" + r.text, flush=True)
    assert r.status_code == 201, r.text
    created = r.json()
    assert "id" in created and created["amount"] == "12.34"
    print("[orders] create assertions passed", flush=True)

    print("[orders] GET /orders", flush=True)
    r = client.get("/orders")
    print(f"[orders] GET status={r.status_code}", flush=True)
    try:
        print("[orders] GET body=\n" + pformat(r.json()), flush=True)
    except Exception:
        print("[orders] GET non-JSON body=\n" + r.text, flush=True)
    assert r.status_code == 200
    items = r.json()
    assert any(o["id"] == created["id"] and o["amount"] == "12.34" for o in items)
    print("[orders] list assertions passed", flush=True)
