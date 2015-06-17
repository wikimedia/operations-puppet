import os
import sys
import getopt
import time
import traceback
import salt.config
import salt.client
import salt.key
from novaclient.v1_1 import client

# fixme sanity checking:
# we want to make sure we don't get bogus results
# for instance exists check (if it's broken what happens?)


class Whiner(object):
    '''
    whine with optional traceback display
    and optional exit
    '''

    @staticmethod
    def whine(message, exc_text=None, fatal=False):
        '''
        display messages and exit if requested
        exc_text is intended for pasing the text of a
        stack trace, though it can of course contain
        anything the caller wishes
        '''

        print message
        if exc_text is not None:
            print "\n%s\n" % exc_text
        if fatal:
            sys.exit(1)


class NovaClient(object):
    '''
    do various (well, a single) operation via
    the nova openstack compute api
    '''

    def __init__(self, authfile, limit=300):
        '''
        authfile: full path to a file of auth creds, see
                  the NovaAuth class for details
        limit:    number of instances to be sent on each
                  request, default 300
        '''
        self.auth = NovaAuth(authfile)
        auth_args = self.auth.get_auth_args()
        self.client = client.Client(*auth_args, service_type='compute')
        self.token = None
        self.limit = limit

    def get_good_instance_hostnames(self):
        '''
        returns a list of hostnames of all good instances
        (status is ACTIVE or ERROR or SHUTOFF)
        for all tenants
        hostnames are structured as name.tenant_id because
        we use that elsewhere, *cough* salt *cough*
        '''
        hostnames = set()
        opts = {'all_tenants': True, 'limit': self.limit}
        while True:
            servers = self.client.servers.list(detailed=True, search_opts=opts)
            if not servers:
                break
            new_hostnames = [getattr(instance, 'name') + "." +
                             getattr(instance, 'tenant_id')
                             for instance in servers]
            hostnames = hostnames | set(new_hostnames)
            opts['marker'] = servers[-1].id
            time.sleep(1)

        if not hostnames:
            Whiner.whine("no good nova instances found, something's wrong",
                         fatal=True)
        return hostnames

    def get_good_instance_ec2id(self):
        '''
        returns a list of ec2 ids of all good instances
        (status is ACTIVE or ERROR or SHUTOFF)
        for all tenants
        '''
        ec2ids = set()
        opts = {'all_tenants': True, 'limit': self.limit}
        while True:
            servers = self.client.servers.list(detailed=True, search_opts=opts)
            if not servers:
                break
            new_ec2ids = [getattr(instance, 'OS-EXT-SRV-ATTR:instance_name')
                          for instance in servers]
            ec2ids = ec2ids | set(new_ec2ids)
            opts['marker'] = servers[-1].id
            time.sleep(1)

        if not ec2ids:
            Whiner.whine("no good nova instances found, something's wrong",
                         fatal=True)
        return ec2ids

    def get_bad_instance_ec2ids(self):
        '''
        # broken until openstack bug with marker + deleted is fixed
        returns a list of ec2 ids of all deleted instances
        (status is DELETED only, not ERROR or BUILD)
        for all tenants
        '''
        ec2ids = set()
        opts = {'all_tenants': True, 'deleted': True, 'limit': self.limit}
        while True:
            servers = self.client.servers.list(detailed=True, search_opts=opts)
            if not servers:
                break
            new_ec2ids = [getattr(instance, 'OS-EXT-SRV-ATTR:instance_name')
                          for instance in servers if
                          instance.status == 'DELETED']
            ec2ids = ec2ids | set(new_ec2ids)
            opts['marker'] = servers[-1].id
            time.sleep(1)
        return ec2ids


class NovaAuth(object):
    '''
    authenticate to nova openstack
    this depends on a file of authentication credentials
    which have lines in the format

    export OS_REGION_NAME="eqiad"

    It must include entries for at least:
    OS_USERNAME, OS_PASSWORD, OS_AUTH_URL,
    OS_REGION_NAME, OS_TENANT_NAME
    '''

    def __init__(self, authfile):
        self.authinfo = {}
        if not os.path.exists(authfile):
            Whiner.whine("authentication credentials file %s does not exist"
                         % authfile)
        try:
            contents = open(authfile, "r").read()
        except:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            except_message = repr(traceback.format_exception(
                exc_type, exc_value, exc_traceback))
            Whiner.whine("failed to get credentials from file %s" %
                         authfile, exc_text=except_message, fatal=True)
        entries = contents.split("\n")
        for entry in entries:
            if not entry.strip() or entry[0] == '#':
                continue
            if '=' not in entry:
                Whiner.whine("ill-formed entry in auth creds file: %s" % entry)
                continue
            if not entry.startswith('export OS_'):
                Whiner.whine("ill-formed entry in auth creds file: %s" % entry)
                continue
            name, value = entry[10:].split('=')
            value = value.strip('"')
            self.authinfo[name] = value

    def get_region(self):
        '''
        return the region associated with the auth credentials
        '''

        return self.authinfo['REGION_NAME']

    def get_auth_args(self):
        '''
        return a dict of authentication credentials
        suitable for using with the nova client api
        '''

        return [self.authinfo['USERNAME'],
                self.authinfo['PASSWORD'],
                self.authinfo['TENANT_NAME'],
                self.authinfo['AUTH_URL']]


class SaltKeys(object):
    '''
    Manage minion salt key operations for a master
    '''

    def __init__(self, timeout=10):
        '''
        timeout is the number of seconds the
        client will wait for the minion response
        '''
        self.client = salt.client.LocalClient()
        self.all_keys = None
        self.accepted_keys = None
        self.key_manager = salt.key.Key(self.client.opts)
        self.timeout = timeout

    def get_accepted_keys(self):
        '''
        get keys of all known salt hosts (accepted)
        '''
        accepted = self.key_manager.list_status('accepted')
        dirnames = accepted.keys()
        self.accepted_keys = []
        for dirname in dirnames:
            self.accepted_keys += accepted[dirname]

    def get_unresponsive_hosts(self):
        '''
        returns a list of salt keys for hosts
        that do not respond to test.ping but are
        known to salt
        '''
        if self.accepted_keys is None:
            self.get_accepted_keys()

        responsive = []
        results = self.client.cmd_batch('*', 'test.ping', bat='100',
                                        timeout=self.timeout)
        for result in results:
            responsive.append(result.keys())
        if not responsive:
            Whiner.whine("no responsive salt hosts, something's wrong",
                         fatal=True)
        return [saltkey for saltkey in self.accepted_keys
                if saltkey not in responsive]

    def delete_bad_key(self, host_name):
        '''
        delete the salt key for the specificied
        host (must be fqdn as known to salt)
        '''

        self.key_manager.delete_key(host_name)


def canonicalize(salt_hostname, region):
    '''
    convert the hostname we get back from a salt
    command to the standard form, tossing the region
    and the 'wmflabs' stuff on the end
    'region' should be eqiad/pmtpa/ etc depending
    on the dc this script runs in
    '''
    domain = '.' + region + '.wmflabs'
    truncate_by = -1 * len(domain)
    if salt_hostname.endswith(domain):
        salt_hostname = salt_hostname[:truncate_by]
    return salt_hostname


def log(message):
    '''
    log information to some logging facility or other
    currently prints to stdout
    '''

    print message


def usage(message=None):
    """
    display a helpful usage message with
    an optional introductory message first
    """
    if message is not None:
        sys.stderr.write(message)
        sys.stderr.write("\n")
    usage_message = """
Usage: cleanup_labs_saltkeys.py [--authfile]
       [--dryrun] [--help]

This script removes salt keys for deleted nova instances.

It relies on salt and on nova.  There should also be a file of
nova authentication credentials ('authfile') someplace in the
following format (order of lines does not matter):

export OS_USERNAME="some-name"
export OS_PASSWORD="password-here"
export OS_AUTH_URL="http://hostname:port/vx.y"
export OS_REGION_NAME="..."
export OS_TENANT_NAME="..."

Lines with # or blank lines are skipped.

If no authfile option is given, the file /root/novaenv.sh is
used.
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def main():
    'main entry point, does all the work'
    authfile = '/root/novaenv.sh'
    dryrun = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "a:dh",
            ["auth=", "dryrun", "help"])

    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))
    for (opt, val) in options:
        if opt in ["-a", "--auth"]:
            authfile = val
        elif opt in ["-h", "--help"]:
            usage('Help for this script\n')
        elif opt in ["-d", "--dryrun"]:
            dryrun = True
        else:
            usage("Unknown option specified: <%s>" % opt)

    if len(remainder) > 0:
        usage("Unknown option(s) specified: <%s>" % remainder[0])

    nova_client = NovaClient(authfile)
    saltkeys = SaltKeys()
    bad_hosts = saltkeys.get_unresponsive_hosts()
    if not bad_hosts:
        # nothing to do
        return

    good_instances = nova_client.get_good_instance_hostnames()

    for bad_key in bad_hosts:
        if (canonicalize(bad_key, nova_client.auth.get_region())
                not in good_instances):
            if not dryrun:
                log("About to delete key %s" % bad_key)
                saltkeys.delete_bad_key(bad_key)
            else:
                print "would delete", bad_key

if __name__ == '__main__':
    main()
