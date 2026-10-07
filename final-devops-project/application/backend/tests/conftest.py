"""Tests run against a throwaway SQLite file, never the real Postgres.

DATABASE_URL has to be set before the app package is imported, because the
engine is created at import time.
"""

import os
import tempfile

import pytest

_tmpdir = tempfile.mkdtemp(prefix="lostfound-test-")
os.environ["DATABASE_URL"] = f"sqlite:///{_tmpdir}/test.db"
os.environ.setdefault("APP_ENV", "test")

from fastapi.testclient import TestClient  # noqa: E402

from app.db import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with TestClient(app) as c:
        yield c


@pytest.fixture()
def wallet(client):
    resp = client.post(
        "/api/items",
        json={
            "kind": "lost",
            "title": "Black leather wallet",
            "description": "Has my library card inside",
            "category": "other",
            "location": "Library 2nd floor",
            "contact": "pratyush@campus.test",
        },
    )
    assert resp.status_code == 201
    return resp.json()
