import os
import subprocess
import uuid
import redis

import flask

app = flask.Flask(__name__)


def check(endpoint):
    def actual_decorator(func):
        def actual_check():
            try:
                ret = func()
                if ret:
                    return "OK", 200
                else:
                    return "NOT OK", 503
            except Exception as e:
                return "Caught exception: %s" % str(e), 503
        # Fix for https://github.com/mitsuhiko/flask/issues/796
        actual_check.__name__ = func.__name__
        return app.route(endpoint)(actual_check)
    return actual_decorator


@check('/nfs/home')
def nfs_home_check():
    content = str(uuid.uuid4())
    path = os.path.join('/data/project/toolschecker/nfs-test/', content)
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


def job_running(name):
    """Check if a job with given name is running"""
    try:
        subprocess.check_call(['/usr/bin/qstat', '-j', name])
        return True
    except subprocess.CalledProcessError:
        return False


@check('/continuous/precise')
def continuous_job_precise():
    return job_running('test-long-running-precise')


@check('/continuous/trusty')
def continuous_job_trusty():
    return job_running('test-long-running-trusty')


@check('/self')
def self_check():
    return True
