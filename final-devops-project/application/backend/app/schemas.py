from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

Kind = Literal["lost", "found"]
Status = Literal["open", "claimed", "closed"]
Category = Literal["electronics", "id-card", "books", "clothing", "keys", "bottle", "other"]


class ItemCreate(BaseModel):
    kind: Kind
    title: str = Field(min_length=3, max_length=120)
    description: str = Field(default="", max_length=1000)
    category: Category = "other"
    location: str = Field(min_length=2, max_length=80)
    contact: str = Field(min_length=3, max_length=80)


class ItemUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=3, max_length=120)
    description: Optional[str] = Field(default=None, max_length=1000)
    category: Optional[Category] = None
    location: Optional[str] = Field(default=None, min_length=2, max_length=80)
    contact: Optional[str] = Field(default=None, min_length=3, max_length=80)
    status: Optional[Status] = None


class ItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    kind: Kind
    title: str
    description: str
    category: str
    location: str
    contact: str
    status: Status
    created_at: datetime
    updated_at: datetime


class Stats(BaseModel):
    total: int
    lost_open: int
    found_open: int
    claimed: int
    closed: int
