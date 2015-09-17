import flask
import ldap
import ldapsupportlib
import os
import pymysql
import redis
import requests
import socket
import subprocess
import time
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


@check('/labsdb/labsdb1001')
def labsdb_check_labsdb1001():
    return db_query_check('labsdb1001.eqiad.wmnet')


@check('/labsdb/labsdb1002')
def labsdb_check_labsdb1002():
    return db_query_check('labsdb1002.eqiad.wmnet')


@check('/labsdb/labsdb1003')
def labsdb_check_labsdb1003():
    return db_query_check('labsdb1003.eqiad.wmnet')


@check('/labsdb/labsdb1004')
def labsdb_check_labsdb1004():
    return db_query_check('labsdb1004.eqiad.wmnet')


@check('/labsdb/labsdb1005')
def labsdb_check_labsdb1005():
    connection = pymysql.connect('labsdb1005.eqiad.wmnet', read_default_file=os.path.expanduser('~/replica.my.cnf'))
    cur = connection.cursor()
    cur.execute('select * from toolserverdb_p.wiki limit 1')
    result = cur.fetchone()
    if result:
        return True
    return False


@check('/dumps')
def dumps_read_check():
    dumpdir = "/public/dumps/public/enwiki"
    dumps = os.listdir(dumpdir)
    statuspath = os.path.join(dumpdir, dumps[0], 'status.html')
    with open(statuspath) as f:
        content = f.read()
    if len(content) > 0:
        return True
    return False


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


def grid_check_start(release):
    """Launch a new job, return True if it starts in 10 seconds"""
    name = 'start-%s-test' % release
    try:
        with open(os.devnull, 'w') as devnull:
            subprocess.check_call(['/usr/bin/jstart', '-N', name,
                                   '-l', 'release=%s' % release,
                                   '/bin/sleep', '600'],
                                  stderr=devnull, stdout=devnull)
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
        with open(os.devnull, 'w') as devnull:
            subprocess.check_call(['/usr/bin/qdel', name],
                                  stderr=devnull, stdout=devnull)
    except subprocess.CalledProcessError:
        return False
    return success


@check('/grid/start/trusty')
def grid_check_start_trusty():
    return grid_check_start('trusty')


@check('/grid/start/precise')
def grid_check_start_precise():
    return grid_check_start('precise')


def db_read_write_check(host, db):
    ''' Write, read, and delete a single record.  The existing db must have
        a table named "test" with one field, also named "test" '''
    success = False
    try:
        connection = pymysql.connect(host, read_default_file=os.path.expanduser('~/replica.my.cnf'), db=db)
        cur = connection.cursor()
        magicnumber = int(time.time())
        cur.execute("INSERT INTO test (test) VALUES (%s)" % magicnumber)
        connection.commit()
        cur.execute("SELECT * FROM test WHERE test=%s" % magicnumber)
        result = cur.fetchone()
        if result:
            cur.execute('DELETE FROM test WHERE test=%s;', magicnumber)
            connection.commit()
            success = True
    finally:
        cur.close()
        connection.close()
    return success


@check('toolsdb')
def check_toolsdb():
    return db_read_write_check('tools-db', 's52524__rwtest')


@check('/self')
def self_check():
    return True
