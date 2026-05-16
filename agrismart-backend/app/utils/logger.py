"""Configuration du système de logging pour KoobalaTech."""

import logging
import sys
from app.config import settings


def configurer_logging() -> None:
    """Configure le logging global de l'application."""
    niveau = logging.DEBUG if settings.env == "development" else logging.INFO

    format_log = "%(asctime)s - %(levelname)s - %(name)s - %(message)s"

    logging.basicConfig(
        level=niveau,
        format=format_log,
        handlers=[
            logging.StreamHandler(sys.stdout),
        ],
    )

    # Silence les loggers verbeux des bibliothèques tierces
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("google.cloud.firestore_v1").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)

    logger = logging.getLogger("koobalatec")
    logger.info(f"Logging configuré — niveau : {logging.getLevelName(niveau)}")
