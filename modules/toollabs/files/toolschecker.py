import flask
import ldap
import ldapsupportlib
import os
import pymysql
import redis
import requests
import socket
import subprocess
import uuid


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


@check('/labs-puppetmaster/eqiad')
def puppet_catalog_check():
    # Verify that we can get this host's catalog from the puppet server
    puppetmaster = "labs-puppetmaster-eqiad.wikimedia.org"
    fqdn = socket.getfqdn()
    keyfile = "/var/lib/toolschecker/puppetcerts/key.pem"
    certfile = "/var/lib/toolschecker/puppetcerts/cert.pem"
    cafile = "/var/lib/toolschecker/puppetcerts/ca.pem"
    url = "https://%s:8140/production/catalog/%s" % (puppetmaster, fqdn)
    request = requests.get(url, verify=cafile, cert=(certfile, keyfile))
    if request.status_code != 200:
        return False
    if 'document_type' in request.json():
        if request.json()['document_type'].lower() == 'catalog'.lower():
            return True
    return False


@check('/labs-dns/private')
def dns_private_check():
    # Verify that we can resolve our own address
    fqdn = socket.getfqdn()
    # This will throw an exception if it can't resolve:
    resolved = socket.gethostbyname_ex(fqdn)
    if len(resolved) == 3:
        if len(resolved[2]) > 0:
            return True
    return False


@check('/ldap')
def ldap_query_check():
    # Run a simple known query and verify that ldap returns something
    ldapConn = ldapsupportlib.LDAPSupportLib().connect()

    query = '(cn=testlabs)'
    base = 'ou=projects,dc=wikimedia,dc=org'
    result = ldapConn.search_s(base, ldap.SCOPE_SUBTREE, query)
    if len(result) > 0:
        return True
    return False


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


def db_query_check(host):
    # Run a simple known query, verify the db returns.
    connection = pymysql.connect(host, read_default_file=os.path.expanduser('~/replica.my.cnf'))
    cur = connection.cursor()
    cur.execute('select * from meta_p.wiki limit 1')
    result = cur.fetchone()
    if result:
        return True
    return False


@check('/labsdb/labstore1001')
def labsdb_check_labstore1001():
    return db_query_check('labstore1001.eqiad.wmnet')


@check('/labsdb/labstore1002')
def labsdb_check_labstore1001():
    return db_query_check('labstore1002.eqiad.wmnet')


@check('/labsdb/labstore1003')
def labsdb_check_labstore1001():
    return db_query_check('labstore1003.eqiad.wmnet')


@check('/labsdb/labstore1004')
def labsdb_check_labstore1001():
    return db_query_check('labstore1004.eqiad.wmnet')


@check('/labsdb/labstore1005')
def labsdb_check_labstore1001():
    return db_query_check('labstore1005.eqiad.wmnet')


def job_running(name):
    """Check if a job with given name is running"""
    try:
        with open(os.devnull, 'w') as devnull:
            subprocess.check_call(['/usr/bin/qstat', '-j', name], stderr=devnull)
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
