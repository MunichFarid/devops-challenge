from pprint import pformat
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_ok():
    print("\n[health] calling GET /health", flush=True)
    r = client.get("/health")
    print(f"[health] status={r.status_code}", flush=True)
    try:
        print("[health] body=\n" + pformat(r.json()), flush=True)
    except Exception:
        print("[health] non-JSON body=\n" + r.text, flush=True)

    assert r.status_code == 200
    assert r.json().get("status") in {"ok", "degraded"}
    print("[health] assertions passed", flush=True)
