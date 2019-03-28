import ConfigParser
import flask
import ldap
import os
import psycopg2
import pymysql
import redis
import requests
import socket
import subprocess
import time
import uuid
import yaml
import pykube


app = flask.Flask(__name__)
app.debug = True


def check(endpoint):
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


@check('/labs-puppetmaster/eqiad')
def puppet_catalog_check():
    # Verify that we can get this host's catalog from the puppet server
    puppetmaster = "labs-puppetmaster.wikimedia.org"
    fqdn = socket.getfqdn()
    keyfile = "/var/lib/toolschecker/puppetcerts/key.pem"
    certfile = "/var/lib/toolschecker/puppetcerts/cert.pem"
    url = "https://%s:8140/production/catalog/%s" % (puppetmaster, fqdn)
    request = requests.get(url, verify=True, cert=(certfile, keyfile))
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


@check('/nfs/secondary_cluster_showmount')
def showmount_check():
    try:
        with open(os.devnull, 'w') as devnull:
            subprocess.check_call(
                ['/sbin/showmount', '-e', 'nfs-tools-project.svc.eqiad.wmnet'],
                stderr=devnull)
        return True
    except subprocess.CalledProcessError:
        return False


@check('/ldap')
def ldap_query_check():
    """
    Run a simple known query and verify that both ldap servers returns something
    """

    with open('/etc/ldap.yaml') as f:
        config = yaml.safe_load(f)
    for server in config['servers']:
        conn = ldap.initialize('ldap://%s:389' % server)
        conn.protocol_version = ldap.VERSION3
        conn.start_tls_s()
        conn.simple_bind_s(config['user'], config['password'])

        query = '(cn=project-testlabs)'
        base = 'ou=groups,dc=wikimedia,dc=org'
        result = conn.search_s(base, ldap.SCOPE_SUBTREE, query)
        if len(result) == 0:
            return False
    return True


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
    connection = pymysql.connect(
        host, read_default_file=os.path.expanduser('~/replica.my.cnf'))
    cur = connection.cursor()
    cur.execute('select * from meta_p.wiki limit 1')
    result = cur.fetchone()
    if result:
        return True
    return False


@check('/labsdb/clouddb1001')
def labsdb_check_clouddb1001():
    connection = pymysql.connect(
        'clouddb1001.clouddb-services.eqiad.wmflabs',
        read_default_file=os.path.expanduser('~/replica.my.cnf')
    )
    cur = connection.cursor()
    cur.execute('select * from toollabs_p.tools limit 1')
    result = cur.fetchone()
    if result:
        return True
    return False


@check('/dumps')
def dumps_read_check():
    dumpdir = "/public/dumps/public/enwiki"
    # dir names in here are YYYYMMDD, 'latest', and maybe some junk
    # this ensures we get the oldest run of the YYYYMMDD ones,
    # which should have a status.html file that is no longer being
    # updated
    dumps = sorted(os.listdir(dumpdir))
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
            subprocess.check_call(
                ['/usr/bin/qstat', '-j', name], stderr=devnull)
        return True
    except subprocess.CalledProcessError:
        return False


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


def db_read_write_check(host, db):
    ''' Write, read, and delete a single record.  The existing db must have
        a table named "test" with one field, also named "test" '''
    success = False
    try:
        connection = pymysql.connect(
            host,
            read_default_file=os.path.expanduser('~/replica.my.cnf'),
            db=db
        )
        cur = connection.cursor()
        magicnumber = int(time.time())
        cur.execute("INSERT INTO test (test) VALUES (%s)" % magicnumber)
        connection.commit()
        cur.execute("SELECT * FROM test WHERE test=%s" % magicnumber)
        result = cur.fetchone()
        if result:
            cur.execute('DELETE FROM test WHERE test=%s' % magicnumber)
            connection.commit()
            success = True
    finally:
        cur.close()
        connection.close()
    return success


@check('/labsdb/wikilabelsrw')
def postgres_read_write_check():
    dbconfig = ConfigParser.RawConfigParser()
    dbconfig.read(os.path.expanduser('~/postgres.my.cnf'))
    user = dbconfig.get('client', 'user')
    password = dbconfig.get('client', 'password')
    magicnumber = int(time.time())

    try:
        connection = psycopg2.connect(
            "host=clouddb1002.clouddb-services.eqiad.wmflabs dbname=%s_rwtest user=%s password=%s"
            % (user, user, password))
        cur = connection.cursor()
        cur.execute("INSERT INTO test (test) VALUES (%s)" % magicnumber)
        connection.commit()
        cur.execute("SELECT * FROM test WHERE test=%s" % magicnumber)
        result = cur.fetchone()
        if result:
            cur.execute('DELETE FROM test WHERE test=%s' % magicnumber)
            connection.commit()
            success = True
    finally:
        cur.close()
        connection.close()
    return success


@check('/toolsdb')
def check_toolsdb():
    return db_read_write_check('tools-db', 's52524__rwtest')


@check('/toolscron')
def cron_check():
    ''' A tools cron job touches a file every five minutes.  This test verifies
        that the mtime is appropriately recent.'''
    filepath = '/data/project/toolschecker/crontest.txt'
    tenminutes = 60 * 10
    mtime = os.path.getmtime(filepath)
    if time.time() - mtime < tenminutes:
        return True
    return False


def check_etcd_health(host):
    # Don't do https verification because we are using puppet certificate for validating
    # it and tools-checker infrastructure runs on the labs puppetmaster because we have a
    # check for the labs puppetmaster in here...
    request = requests.get('https://{host}:2379/health'.format(host=host), timeout=3, verify=False)
    if request.status_code == 200:
        return request.json()['health'] == 'true'
    return False


@check('/etcd/flannel')
def flannel_etcd_check():
    hosts = [
        'tools-flannel-etcd-01.tools.eqiad.wmflabs',
        'tools-flannel-etcd-02.tools.eqiad.wmflabs',
        'tools-flannel-etcd-03.tools.eqiad.wmflabs',
    ]
    return all([check_etcd_health(host) for host in hosts])


@check('/etcd/k8s')
def kubernetes_etcd_check():
    hosts = [
        'tools-k8s-etcd-01.tools.eqiad.wmflabs',
        'tools-k8s-etcd-02.tools.eqiad.wmflabs',
        'tools-k8s-etcd-03.tools.eqiad.wmflabs',
    ]
    return all([check_etcd_health(host) for host in hosts])


def get_kubernetes_api():
    api = pykube.HTTPClient(
        pykube.KubeConfig.from_file(
            os.path.expanduser('~/.kube/config')
        )
    )
    return api


@check('/k8s/nodes/ready')
def kubernetes_nodes_ready_check():
    """
    Check that no nodes are in NonReady but Schedulable state
    """
    api = get_kubernetes_api()
    nodes = list(pykube.Node.objects(api))
    for node in nodes:
        is_ready = False
        for condition in node.obj['status']['conditions']:
            if condition['type'] == 'Ready' and condition['status'] == 'True':
                is_ready = True
                break
        if not is_ready:
            if node.obj['spec'].get('unschedulable', False):
                # If node isn't ready but is marked as unschedulable (cordoned), is ok
                continue
            return False
    return True


@check('/webservice/kubernetes')
def webservice_kubernetes_test():
    """
    Start a simple kubernetes webservice, verify that it can serve a page
    within 10 seconds.
    """
    success = False
    url = "https://tools.wmflabs.org/toolschecker-k8s-ws/"
    subprocess.check_call([
        'sudo',
        '-u', 'tools.toolschecker-k8s-ws',
        '-i',
        '/usr/bin/webservice',
        '--backend=kubernetes',
        'start',
    ])

    for i in range(0, 10):
        request = requests.get(url)
        if request.status_code == 200:
            success = True
            break
        time.sleep(1)

    subprocess.check_call([
        'sudo',
        '-u', 'tools.toolschecker-k8s-ws',
        '-i',
        '/usr/bin/webservice',
        '--backend=kubernetes',
        'stop',
    ])

    # If we never succeeded in the starting of the webservice, fail!
    # We put this here after the stop so we don't end up with accidental failures
    # that leave a stray webservice running
    if not success:
        return False

    # If we did start it, make sure it really stopped
    success = False
    for i in range(0, 10):
        request = requests.get(url)
        if request.status_code != 200:
            success = True
            break
        time.sleep(1)

    return success


@check('/service/start')
def service_start_test():
    """
    Start a couple of simple web services, verify that they can serve a page
    within 10 seconds.
    """
    success = False
    url = "https://tools.wmflabs.org/toolschecker-ge-ws/"
    subprocess.check_call([
        'sudo',
        '-u', 'tools.toolschecker-ge-ws',
        '-i',
        '/usr/bin/webservice', 'start'
    ])

    for i in range(0, 10):
        request = requests.get(url)
        if request.status_code == 200:
            success = True
            break
        time.sleep(1)

    subprocess.check_call([
        'sudo',
        '-u', 'tools.toolschecker-ge-ws',
        '-i',
        '/usr/bin/webservice', 'stop'
    ])

    # Make sure it really stopped
    success = success and False
    for i in range(0, 10):
        request = requests.get(url)
        if request.status_code != 200:
            success = True
            break
        time.sleep(1)

    return success


@check('/self')
def self_check():
    return True
