#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 Wikimedia Foundation All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including without
# limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to
# whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
import configparser
import json
import logging.config
import os
import socket
import subprocess
import time
import uuid

import flask
import ldap3
import psycopg2
import pymysql
import redis
import requests
import yaml


logging.config.dictConfig({
    "version": 1,
    "formatters": {
        "default": {
            "format": "%(name)s %(levelname)s: %(message)s",
        },
    },
    "handlers": {
        "wsgi": {
            "class": "logging.StreamHandler",
            "formatter": "default",
            "level": "DEBUG",
        },
    },
    "root": {
        "handlers": ["wsgi"],
        "level": "INFO",
    },
})
app = flask.Flask(__name__)
__dir__ = os.path.dirname(__file__)
app.config.update(yaml.safe_load(open(os.path.join(__dir__, 'config.yaml'))))


def check(endpoint):
    """A decorator that is used to register a check function for a given URL
    rule.

    The decorated function is expected to return a truthy value if the check
    succeeded, and a falsy value otherwise.
    """

    def actual_decorator(func):
        def actual_check():
            try:
                ret = func()
                if ret:
                    return "OK", 200
                else:
                    return "FAIL", 503
            except Exception as e:
                return "Caught exception: %s" % str(e), 503

        # Fix for https://github.com/mitsuhiko/flask/issues/796
        actual_check.__name__ = func.__name__
        return app.route(endpoint)(actual_check)

    return actual_decorator


@check("/cron")
def cron_check():
    """A tools cron job touches a file every five minutes.

    This test verifies that the mtime is appropriately recent."""
    filepath = app.config["CRON_PATH"]
    tenminutes = 60 * 10
    mtime = os.path.getmtime(filepath)
    if time.time() - mtime < tenminutes:
        return True
    return False


def mysql_query_check(host, query):
    """Run a simple known query, verify the db returns."""
    connection = pymysql.connect(
        host,
        read_default_file=os.path.join(__dir__, 'replica.my.cnf'),
    )
    cur = connection.cursor()
    cur.execute(query)
    result = cur.fetchone()
    if result:
        return True
    return False


def mysql_read_write_check(host, db):
    """Write, read, and delete a single record.

    The existing db must have a table named 'test' with one field, also named
    'test'"""
    success = False
    try:
        connection = pymysql.connect(
            host,
            read_default_file=os.path.join(__dir__, 'replica.my.cnf'),
            db=db
        )
        cur = connection.cursor()
        magicnumber = int(time.time())
        cur.execute("INSERT INTO test (test) VALUES (%s)" % magicnumber)
        connection.commit()
        cur.execute("SELECT * FROM test WHERE test=%s" % magicnumber)
        result = cur.fetchone()
        if result:
            cur.execute("DELETE FROM test WHERE test=%s" % magicnumber)
            connection.commit()
            success = True
    finally:
        if cur:
            cur.close()
        if connection:
            connection.close()
    return success


@check("/db/toolsdb")
def db_toolsdb():
    return mysql_read_write_check(
        "tools.db.svc.eqiad.wmflabs",
        "s52524__rwtest"
    )


@check("/db/wikilabelsrw")
def postgres_read_write_check():
    dbconfig = configparser.RawConfigParser()
    dbconfig.read(os.path.join(__dir__, 'postgres.my.cnf'))
    user = dbconfig.get("client", "user")
    password = dbconfig.get("client", "password")
    magicnumber = int(time.time())

    try:
        connection = psycopg2.connect(
            host="wikilabels.db.svc.eqiad.wmflabs",
            dbname="{}_rwtest".format(user),
            user=user,
            password=password,
        )
        cur = connection.cursor()
        cur.execute("INSERT INTO test (test) VALUES (%s)" % magicnumber)
        connection.commit()
        cur.execute("SELECT * FROM test WHERE test=%s" % magicnumber)
        result = cur.fetchone()
        if result:
            cur.execute("DELETE FROM test WHERE test=%s" % magicnumber)
            connection.commit()
            success = True
    finally:
        cur.close()
        connection.close()
    return success


@check("/dns/private")
def dns_private_check():
    """Verify that we can resolve the local fqdn."""
    fqdn = socket.getfqdn()
    # This will throw an exception if it can't resolve:
    resolved = socket.gethostbyname_ex(fqdn)
    if len(resolved) == 3:
        if len(resolved[2]) > 0:
            return True
    return False


def check_etcd_health(host):
    # Don't do https verification because we are using puppet certificate for
    # validating it and tools-checker infrastructure runs on the labs
    # puppetmaster because we have a check for the labs puppetmaster in
    # here...
    request = requests.get(
        "https://{host}:2379/health".format(host=host),
        timeout=3,
        verify=False
    )
    if request.status_code == 200:
        return request.json()["health"] == "true"
    return False


@check("/etcd/flannel")
def flannel_etcd_check():
    hosts = app.config["ETCD_FLANNEL"]
    return all([check_etcd_health(host) for host in hosts])


@check("/etcd/k8s")
def kubernetes_etcd_check():
    hosts = app.config["ETCD_K8S"]
    return all([check_etcd_health(host) for host in hosts])


def job_running(name):
    """Check if a job with given name is running"""
    try:
        with open(os.devnull, "w") as devnull:
            subprocess.check_call(
                [
                    "sudo",
                    "-u", "{}.toolschecker".format(app.config["PROJECT"]),
                    "/usr/bin/qstat", "-j", name
                ],
                stderr=devnull
            )
        return True
    except subprocess.CalledProcessError:
        return False


@check("/grid/continuous/stretch")
def grid_continuous_stretch():
    return job_running("test-long-running-stretch")


def grid_check_start(release):
    """Launch a new job, return True if it starts in 10 seconds"""
    name = "start-{}-test".format(release)
    try:
        with open(os.devnull, "w") as devnull:
            subprocess.check_call(
                [
                    "sudo",
                    "-u", "{}.toolschecker".format(app.config["PROJECT"]),
                    "/usr/bin/jstart",
                    "-N", name,
                    "-l", "release={}".format(release),
                    "/bin/sleep", "600",
                ],
                stderr=devnull,
                stdout=devnull,
            )
    except subprocess.CalledProcessError:
        return False

    success = False
    for i in range(0, 10):
        if job_running(name):
            success = True
            break
        time.sleep(1)
    # clean up, whether or not it started
    try:
        with open(os.devnull, "w") as devnull:
            subprocess.check_call(
                [
                    "sudo",
                    "-u", "{}.toolschecker".format(app.config["PROJECT"]),
                    "/usr/bin/qdel", name
                ],
                stderr=devnull,
                stdout=devnull,
            )
    except subprocess.CalledProcessError:
        return False
    return success


@check("/grid/start/stretch")
def grid_start_stretch():
    """Verify that we can start a job on the Stretch grid."""
    return grid_check_start("stretch")


@check("/k8s/nodes/ready")
def kubernetes_nodes_ready_check():
    """Check that no nodes are in NonReady but Schedulable state"""
    with open(os.path.join(__dir__, 'kubernetes.json')) as dotfile:
        config = json.load(dotfile)
    apiserver = config["clusters"][0]["cluster"]["server"]
    token = config["users"][0]["user"]["token"]

    r = requests.get(
        "{}/api/v1/nodes".format(apiserver),
        headers={"Authorization": "Bearer {}".format(token)},
    )
    for node in r.json()["items"]:
        is_ready = False
        for condition in node["status"]["conditions"]:
            if condition["type"] == "Ready" and condition["status"] == "True":
                is_ready = True
                break
        if not is_ready:
            if node["spec"].get("unschedulable", False):
                # If node isn't ready but is marked as unschedulable
                # (cordoned), is ok
                continue
            return False
    return True


@check("/ldap")
def ldap_query_check():
    """Run a simple known query and verify that all ldap servers return
    something."""
    with open("/etc/ldap.yaml") as f:
        config = yaml.safe_load(f)

    for server in config["servers"]:
        svr = ldap3.Server(server)
        conn = ldap3.Connection(
            server=svr,
            user=config["user"],
            password=config["password"],
            auto_bind=ldap3.AUTO_BIND_TLS_BEFORE_BIND,
            read_only=True,
        )
        conn.search(
            "ou=groups,dc=wikimedia,dc=org",
            "(cn=project-testlabs)",
            ldap3.SUBTREE,
            attributes=["member", "cn"],
            time_limit=5,
        )
        if len(conn.entries) == 0:
            return False
    return True


@check("/nfs/dumps")
def dumps_read_check():
    dumpdir = app.config["DUMPS_PATH"]
    # dir names in here are YYYYMMDD, 'latest', and maybe some junk
    # this ensures we get the oldest run of the YYYYMMDD ones,
    # which should have a status.html file that is no longer being
    # updated
    dumps = sorted(os.listdir(dumpdir))
    statuspath = os.path.join(dumpdir, dumps[0], "status.html")
    with open(statuspath) as f:
        content = f.read()
    if len(content) > 0:
        return True
    return False


@check("/nfs/home")
def nfs_home_check():
    """Verify that we can write to an NFS share and read what we wrote."""
    content = str(uuid.uuid4())
    path = os.path.join(app.config["NFS_HOME_PATH"], content)
    try:
        with open(path, "w") as f:
            f.write(content)

        with open(path) as f:
            actual_content = f.read()

        if actual_content == content:
            return True
        return False
    finally:
        os.remove(path)


@check("/nfs/secondary_cluster_showmount")
def showmount_check():
    try:
        with open(os.devnull, "w") as devnull:
            subprocess.check_call(
                ["/sbin/showmount", "-e", "nfs-tools-project.svc.eqiad.wmnet"],
                stderr=devnull,
            )
        return True
    except subprocess.CalledProcessError:
        return False


@check("/redis")
def redis_check():
    """Verify that we can write, read, and delete a Redis key."""
    red = redis.StrictRedis(host="tools-redis")
    content = "toolschecker-check-{}".format(str(uuid.uuid4()))
    try:
        if not red.set(content, content):
            app.logger.error("redis: Failed to set %s", content)
            return False
        ret = red.get(content)
        if not ret:
            app.logger.error("redis: Failed to get %s", content)
            return False
        if ret.decode("utf-8") != content:
            app.logger.error("redis: Expected %s, got %s", content, ret)
            return False
    finally:
        if not red.delete(content):
            app.logger.warning("redis: Failed to delete %s", content)
    return True


@check("/self")
def self_check():
    return True


def start_stop_webservice(tool, backend, wstype):
    """Start a webservice, poll it for a 200 response, shut it down."""

    webservice = [
        "sudo",
        "-u",
        "{}.{}".format(app.config["PROJECT"], tool),
        "-i",
        "/usr/bin/webservice",
        "--backend={}".format(backend),
        wstype,
    ]

    # Check for existing webservices
    for _ in range(0, 3):
        websvc_status = subprocess.check_output(webservice + ["status"])
        if "not running" in websvc_status.decode().strip():
            break
        time.sleep(3)
    else:
        # Waited long enough and unable to proceed
        app.logger.error("webservice %s: found existing webservice running", backend)
        return False

    # Start webservice
    websvc_start = subprocess.run(webservice + ["start"], stdout=subprocess.DEVNULL)
    if websvc_start.returncode:
        app.logger.error("webservice %s: error starting", backend)
        return False

    # Poll webservice for a 200 OK response
    url = "https://{}/{}/".format(app.config["TOOLS_DOMAIN"], tool)
    for i in range(0, 60):
        request = requests.get(url)
        if request.status_code == 200:
            app.logger.info("webservice %s: Response at %s", backend, i)
            break
        time.sleep(1)
    else:
        app.logger.error("webservice %s: No response after 60s", backend)
        return False

    # Stop webservice
    websvc_stop = subprocess.run(webservice + ["stop"], stdout=subprocess.DEVNULL)
    if websvc_stop.returncode:
        app.logger.error("webservice %s: error stopping", backend)
        return False

    # Verify webservice is stopped and return True
    for _ in range(0, 10):
        request = requests.get(url)
        if request.status_code != 200:
            return True
        time.sleep(1)

    app.logger.error("webservice %s: failed to stop", backend)
    return False


@check("/webservice/gridengine")
def webservice_gridengine_test():
    """Start a simple web service, verify that it can serve a page within 10
    seconds."""
    return start_stop_webservice(
        "toolschecker-ge-ws",
        "gridengine",
        "lighttpd"
    )


@check("/webservice/kubernetes")
def webservice_kubernetes_test():
    """Start a simple kubernetes webservice, verify that it can serve a page
    within 10 seconds."""
    return start_stop_webservice(
        "toolschecker-k8s-ws",
        "kubernetes",
        "php7.2"
    )
