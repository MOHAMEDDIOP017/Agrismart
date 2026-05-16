"""Client Redis async — cache pour tokens Firebase et profils utilisateurs."""

import hashlib
import json
import logging
from datetime import datetime
from typing import Any, Optional

import redis.asyncio as aioredis

from app.config import settings

logger = logging.getLogger(__name__)

_redis_client: Optional[aioredis.Redis] = None


def _get_client() -> aioredis.Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = aioredis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=2,
            socket_timeout=2,
        )
    return _redis_client


class _DatetimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)


def _serialize(data: Any) -> str:
    return json.dumps(data, cls=_DatetimeEncoder)


def _deserialize(raw: str) -> Any:
    return json.loads(raw)


def token_cache_key(token: str) -> str:
    digest = hashlib.sha256(token.encode()).hexdigest()[:32]
    return f"koobalatec:token:{digest}"


def profil_cache_key(uid: str) -> str:
    return f"koobalatec:user:{uid}"


async def get_cached(key: str) -> Optional[Any]:
    try:
        client = _get_client()
        raw = await client.get(key)
        if raw:
            logger.debug(f"[Cache HIT] {key}")
            return _deserialize(raw)
    except Exception as e:
        logger.warning(f"[Cache] Erreur lecture {key} : {e}")
    return None


async def set_cached(key: str, value: Any, ttl: int) -> None:
    try:
        client = _get_client()
        await client.setex(key, ttl, _serialize(value))
        logger.debug(f"[Cache SET] {key} (TTL={ttl}s)")
    except Exception as e:
        logger.warning(f"[Cache] Erreur écriture {key} : {e}")


async def delete_cached(key: str) -> None:
    try:
        client = _get_client()
        await client.delete(key)
        logger.debug(f"[Cache DEL] {key}")
    except Exception as e:
        logger.warning(f"[Cache] Erreur suppression {key} : {e}")


async def close() -> None:
    global _redis_client
    if _redis_client:
        await _redis_client.aclose()
        _redis_client = None
