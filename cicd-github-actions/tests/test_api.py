import pytest

from app import __version__, create_app


@pytest.fixture
def client(monkeypatch):
    monkeypatch.delenv("ADMIN_API_KEY", raising=False)
    monkeypatch.setenv("GIT_SHA", "abc1234")
    return create_app().test_client()


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_version_reports_build_commit(client):
    assert client.get("/version").get_json() == {"version": __version__, "commit": "abc1234"}


def test_grade_endpoint(client):
    resp = client.get("/api/grade?score=84")
    assert resp.status_code == 200
    assert resp.get_json() == {"score": 84.0, "grade": "A+", "points": 9}


@pytest.mark.parametrize("query", ["", "?score=", "?score=abc", "?score=101"])
def test_grade_endpoint_rejects_bad_input(client, query):
    resp = client.get(f"/api/grade{query}")
    assert resp.status_code == 400
    assert "error" in resp.get_json()


def test_sgpa_endpoint(client):
    body = {"courses": [{"name": "OS", "credits": 4, "score": 68}, {"credits": 2, "score": 92}]}
    resp = client.post("/api/sgpa", json=body)
    assert resp.status_code == 200
    assert resp.get_json()["sgpa"] == 8.0  # (7*4 + 10*2) / 6


def test_sgpa_endpoint_needs_json(client):
    assert client.post("/api/sgpa", data="not json").status_code == 400


def test_admin_disabled_without_key(client):
    assert client.get("/api/admin/stats").status_code == 503


def test_admin_requires_correct_key(client, monkeypatch):
    monkeypatch.setenv("ADMIN_API_KEY", "test-key-123")
    assert client.get("/api/admin/stats").status_code == 401
    assert client.get("/api/admin/stats", headers={"X-API-Key": "wrong"}).status_code == 401

    client.get("/api/grade?score=50")
    resp = client.get("/api/admin/stats", headers={"X-API-Key": "test-key-123"})
    assert resp.status_code == 200
    assert resp.get_json()["requests_served"]["grade"] == 1
