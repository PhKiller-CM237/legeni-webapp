from unittest.mock import Mock

from app import RedisCounter, build_counter


def test_build_memory(monkeypatch):
    monkeypatch.delenv("REDIS_HOST", raising=False)
    assert build_counter().name == "memoire"


def test_build_redis(monkeypatch):
    monkeypatch.setenv("REDIS_HOST", "redis")
    monkeypatch.setenv("REDIS_PORT", "6380")
    monkeypatch.setenv("REDIS_PASSWORD", "test-password")
    counter = build_counter()
    assert counter.client.connection_pool.connection_kwargs["port"] == 6380


def test_redis_counter(monkeypatch):
    counter = RedisCounter("redis", 6379)
    counter.client = Mock()
    counter.client.incr.return_value = 7
    counter.client.ping.return_value = True
    assert counter.incr() == 7
    assert counter.ping()
    counter.client.ping.return_value = False
    assert not counter.ping()
    counter.client.ping.side_effect = ConnectionError("offline")
    assert not counter.ping()
