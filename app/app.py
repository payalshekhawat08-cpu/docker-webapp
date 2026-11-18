import os
import socket

import redis
from flask import Flask, jsonify

app = Flask(__name__)

MESSAGE = os.getenv("APP_MESSAGE", "Hello from Docker!")

cache = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
)


@app.route("/")
def index():
    try:
        visits = cache.incr("visits")
    except redis.exceptions.RedisError:
        return jsonify(error="Cannot reach Redis"), 503
    return jsonify(
        message=MESSAGE,
        visits=visits,
        container=socket.gethostname(),
    )


@app.route("/health")
def health():
    try:
        cache.ping()
    except redis.exceptions.RedisError:
        return jsonify(status="redis unavailable"), 503
    return jsonify(status="ok")
