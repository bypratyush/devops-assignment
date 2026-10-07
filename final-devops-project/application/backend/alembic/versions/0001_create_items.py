"""create items table

Revision ID: 0001
Revises:
Create Date: 2026-10-07
"""

import sqlalchemy as sa

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("kind", sa.String(10), nullable=False),
        sa.Column("title", sa.String(120), nullable=False),
        sa.Column("description", sa.Text(), nullable=False, server_default=""),
        sa.Column("category", sa.String(40), nullable=False, server_default="other"),
        sa.Column("location", sa.String(80), nullable=False),
        sa.Column("contact", sa.String(80), nullable=False),
        sa.Column("status", sa.String(10), nullable=False, server_default="open"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_items_kind_status", "items", ["kind", "status"])


def downgrade() -> None:
    op.drop_index("ix_items_kind_status", table_name="items")
    op.drop_table("items")
