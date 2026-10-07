import socket
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Query, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import models, schemas
from .config import settings
from .db import db_is_up, get_db
from .observability import DB_UP, ITEMS_REPORTED, metrics_middleware, setup_logging

log = setup_logging(settings.log_level)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    log.info(
        "starting",
        extra={
            "extra_fields": {
                "env": settings.app_env,
                "version": settings.app_version,
                "db_host": settings.db_host,
            }
        },
    )
    yield


app = FastAPI(title="Campus Lost & Found API", version=settings.app_version, lifespan=lifespan)
app.middleware("http")(metrics_middleware)


# ---- probes and metrics ---------------------------------------------------


@app.get("/health")
def health():
    """Liveness: the process is up. Deliberately does NOT touch the database,
    so a DB outage makes pods unready instead of restarting all of them."""
    return {"status": "ok"}


@app.get("/ready")
def ready(response: Response):
    """Readiness: only take traffic when the database answers."""
    up = db_is_up()
    DB_UP.set(1 if up else 0)
    if not up:
        response.status_code = 503
        return {"status": "unavailable", "database": "down"}
    return {"status": "ready", "database": "up"}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/info")
def info():
    return {
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.app_env,
        "pod": socket.gethostname(),
        "notice": settings.notice,
    }


# ---- items -----------------------------------------------------------------


def _get_or_404(db: Session, item_id: int) -> models.Item:
    item = db.get(models.Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail=f"item {item_id} not found")
    return item


@app.get("/api/items", response_model=list[schemas.ItemOut])
def list_items(
    kind: Optional[schemas.Kind] = None,
    status: Optional[schemas.Status] = None,
    q: Optional[str] = Query(default=None, max_length=50),
    db: Session = Depends(get_db),
):
    stmt = select(models.Item).order_by(models.Item.created_at.desc(), models.Item.id.desc())
    if kind:
        stmt = stmt.where(models.Item.kind == kind)
    if status:
        stmt = stmt.where(models.Item.status == status)
    if q:
        like = f"%{q.lower()}%"
        stmt = stmt.where(
            func.lower(models.Item.title).like(like) | func.lower(models.Item.location).like(like)
        )
    return db.scalars(stmt).all()


@app.get("/api/items/{item_id}", response_model=schemas.ItemOut)
def get_item(item_id: int, db: Session = Depends(get_db)):
    return _get_or_404(db, item_id)


@app.post("/api/items", response_model=schemas.ItemOut, status_code=201)
def create_item(payload: schemas.ItemCreate, db: Session = Depends(get_db)):
    item = models.Item(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    ITEMS_REPORTED.labels(item.kind).inc()
    log.info("item reported", extra={"extra_fields": {"item_id": item.id, "kind": item.kind}})
    return item


@app.put("/api/items/{item_id}", response_model=schemas.ItemOut)
def update_item(item_id: int, payload: schemas.ItemUpdate, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return item


@app.delete("/api/items/{item_id}", status_code=204)
def delete_item(item_id: int, db: Session = Depends(get_db)):
    item = _get_or_404(db, item_id)
    db.delete(item)
    db.commit()
    return Response(status_code=204)


@app.get("/api/stats", response_model=schemas.Stats)
def stats(db: Session = Depends(get_db)):
    rows = db.execute(
        select(models.Item.kind, models.Item.status, func.count()).group_by(
            models.Item.kind, models.Item.status
        )
    ).all()
    counts = {(k, s): n for k, s, n in rows}
    return schemas.Stats(
        total=sum(counts.values()),
        lost_open=counts.get(("lost", "open"), 0),
        found_open=counts.get(("found", "open"), 0),
        claimed=sum(n for (k, s), n in counts.items() if s == "claimed"),
        closed=sum(n for (k, s), n in counts.items() if s == "closed"),
    )
