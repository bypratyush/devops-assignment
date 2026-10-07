"""Runtime configuration, read from environment variables.

In Kubernetes the non-secret values come from a ConfigMap and DB_PASSWORD
comes from a Secret, so nothing environment-specific is baked into the image.
"""

import os
from urllib.parse import quote_plus


class Settings:
    def __init__(self) -> None:
        self.app_name = os.getenv("APP_NAME", "Campus Lost & Found")
        self.app_env = os.getenv("APP_ENV", "local")
        self.app_version = os.getenv("APP_VERSION", "dev")
        self.log_level = os.getenv("LOG_LEVEL", "INFO").upper()
        self.notice = os.getenv("CAMPUS_NOTICE", "")

        self.db_host = os.getenv("DB_HOST", "localhost")
        self.db_port = int(os.getenv("DB_PORT", "5432"))
        self.db_name = os.getenv("DB_NAME", "lostfound")
        self.db_user = os.getenv("DB_USER", "lostfound")
        self.db_password = os.getenv("DB_PASSWORD", "")
        # DATABASE_URL wins if set (tests use sqlite through it)
        self._database_url = os.getenv("DATABASE_URL", "")

    @property
    def database_url(self) -> str:
        if self._database_url:
            return self._database_url
        return (
            f"postgresql+psycopg://{quote_plus(self.db_user)}:{quote_plus(self.db_password)}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )


settings = Settings()
