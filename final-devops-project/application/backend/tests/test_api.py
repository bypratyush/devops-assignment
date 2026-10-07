def test_health_does_not_need_db(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_ready_reports_database(client):
    resp = client.get("/ready")
    assert resp.status_code == 200
    assert resp.json()["database"] == "up"


def test_create_item(client):
    resp = client.post(
        "/api/items",
        json={
            "kind": "found",
            "title": "Blue water bottle",
            "category": "bottle",
            "location": "Basketball court",
            "contact": "desk@campus.test",
        },
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["id"] > 0
    assert body["status"] == "open"
    assert body["kind"] == "found"


def test_create_rejects_bad_kind(client):
    resp = client.post(
        "/api/items",
        json={"kind": "stolen", "title": "Bike", "location": "Gate 2", "contact": "x@y.z"},
    )
    assert resp.status_code == 422


def test_create_rejects_short_title(client):
    resp = client.post(
        "/api/items",
        json={"kind": "lost", "title": "ab", "location": "Gate 2", "contact": "x@y.z"},
    )
    assert resp.status_code == 422


def test_list_and_filter(client, wallet):
    client.post(
        "/api/items",
        json={
            "kind": "found",
            "title": "Casio calculator",
            "category": "electronics",
            "location": "Exam hall B",
            "contact": "desk@campus.test",
        },
    )
    all_items = client.get("/api/items").json()
    assert len(all_items) == 2
    lost = client.get("/api/items", params={"kind": "lost"}).json()
    assert [i["title"] for i in lost] == ["Black leather wallet"]
    search = client.get("/api/items", params={"q": "exam"}).json()
    assert [i["title"] for i in search] == ["Casio calculator"]


def test_get_item_and_404(client, wallet):
    assert client.get(f"/api/items/{wallet['id']}").json()["title"] == "Black leather wallet"
    resp = client.get("/api/items/9999")
    assert resp.status_code == 404


def test_update_status_to_claimed(client, wallet):
    resp = client.put(f"/api/items/{wallet['id']}", json={"status": "claimed"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "claimed"
    # untouched fields stay as they were
    assert resp.json()["location"] == "Library 2nd floor"


def test_update_rejects_unknown_status(client, wallet):
    resp = client.put(f"/api/items/{wallet['id']}", json={"status": "lost-forever"})
    assert resp.status_code == 422


def test_delete_item(client, wallet):
    assert client.delete(f"/api/items/{wallet['id']}").status_code == 204
    assert client.get(f"/api/items/{wallet['id']}").status_code == 404
    assert client.delete(f"/api/items/{wallet['id']}").status_code == 404


def test_stats(client, wallet):
    client.post(
        "/api/items",
        json={
            "kind": "found",
            "title": "Hostel room key",
            "category": "keys",
            "location": "Mess",
            "contact": "desk@campus.test",
        },
    )
    client.put(f"/api/items/{wallet['id']}", json={"status": "closed"})
    assert client.get("/api/stats").json() == {
        "total": 2,
        "lost_open": 0,
        "found_open": 1,
        "claimed": 0,
        "closed": 1,
    }


def test_metrics_exposed(client, wallet):
    client.get("/api/items")
    text = client.get("/metrics").text
    assert "lostfound_http_requests_total" in text
    assert 'route="/api/items"' in text
    assert 'lostfound_items_reported_total{kind="lost"}' in text


def test_info_shows_environment(client):
    body = client.get("/api/info").json()
    assert body["environment"] == "test"
    assert "pod" in body
