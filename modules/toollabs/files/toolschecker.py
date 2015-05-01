import os
import uuid
import time
import redis

import flask

app = flask.Flask(__name__)


def check(endpoint):
    def actual_decorator(func):
        def actual_check():
            start_time = time.time()
            ret = func()
            total_time = time.time() - start_time
            return flask.jsonify(
                status=ret,
                time=total_time
            )
        # Fix for https://github.com/mitsuhiko/flask/issues/796
        actual_check.__name__ = func.__name__
        return app.route(endpoint)(actual_check)
    return actual_decorator


@check('/nfs/home')
def nfs_home_check():
    content = str(uuid.uuid4())
    path = os.path.join('/data/project/canary/nfs-test/', content)
    try:
        with open(path, 'w') as f:
            f.write(content)

        with open(path) as f:
            actual_content = f.read()

        if actual_content == content:
            return True
        return False
    finally:
        os.remove(path)


@check('/redis')
def redis_check():
    red = redis.StrictRedis(host='tools-redis')
    content = str(uuid.uuid4())
    try:
        red.set(content, content)
        return red.get(content) == content
    finally:
        red.delete(content)


@check('/self')
def self_check():
    return True
