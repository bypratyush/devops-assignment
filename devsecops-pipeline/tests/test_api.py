import pytest

from passguard import __version__, create_app


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("GIT_SHA", "abc1234")
    return create_app().test_client()


def test_probes(client):
    assert client.get("/healthz").get_json() == {"status": "ok"}
    assert client.get("/readyz").get_json() == {"ready": True}


def test_version(client):
    assert client.get("/version").get_json() == {"version": __version__, "commit": "abc1234"}


def test_index_page_has_security_headers(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"PassGuard" in resp.data
    assert resp.headers["X-Frame-Options"] == "DENY"
    assert "default-src 'self'" in resp.headers["Content-Security-Policy"]
    assert resp.headers["X-Content-Type-Options"] == "nosniff"


def test_strength_endpoint(client):
    resp = client.post("/api/strength", json={"password": "qwerty"})
    assert resp.status_code == 200
    assert resp.get_json()["label"] == "very weak"
    assert resp.headers["Cache-Control"] == "no-store"


@pytest.mark.parametrize("body", [{}, {"password": ""}, {"password": 42}])
def test_strength_rejects_bad_input(client, body):
    assert client.post("/api/strength", json=body).status_code == 400


def test_oversized_body_is_refused(client):
    assert client.post("/api/strength", json={"password": "a" * 10_000}).status_code == 413


def test_generate_endpoint(client):
    data = client.get("/api/generate?length=24").get_json()
    assert len(data["password"]) == 24
    assert data["score"] >= 3
    assert "feedback" not in data


@pytest.mark.parametrize("length", ["abc", "8", "100"])
def test_generate_rejects_bad_length(client, length):
    assert client.get(f"/api/generate?length={length}").status_code == 400
