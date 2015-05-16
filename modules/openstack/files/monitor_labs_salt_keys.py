import os
import sys
import getopt
import time
import traceback
import salt.config
import salt.client
import salt.key
from novaclient.v1_1 import client


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

    @staticmethod
    def instance_display(server):
        '''
        given a nova server object (returned by listing
        servers), display a few useful fields from it
        '''

        print 'Instance:', getattr(server, 'OS-EXT-SRV-ATTR:instance_name'),
        print 'Status:', server.status,
        print 'hostname:', server.name,
        if 'public' in server.addresses and server.addresses['public']:
            print 'IP:', server.addresses['public'][0]['addr'],
        else:
            print 'IP: seems to have none',
        print 'Hypervisor:',
        print getattr(server, 'OS-EXT-SRV-ATTR:hypervisor_hostname'),
        if server.tenant_id == 'deployment-prep':
            print 'Salt-master: deployment-salt'
        else:
            print
        if hasattr(server, 'fault'):
            print 'Fault:', server.fault

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

    def get_good_instances(self):
        '''
        returns a list of ec2 ids of all good instances
        (status is ACTIVE or ERROR or SHUTOFF)
        for all tenants
        '''
        instances = {}
        opts = {'all_tenants': True, 'limit': self.limit}
        while True:
            servers = self.client.servers.list(detailed=True, search_opts=opts)
            if not servers:
                break
            for instance in servers:
                instances[getattr(instance,
                                  'OS-EXT-SRV-ATTR:instance_name')] = instance
            opts['marker'] = servers[-1].id
            time.sleep(1)

        if not instances:
            Whiner.whine("no good nova instances found, something's wrong",
                         fatal=True)
        return instances

    def get_bad_instances(self):
        '''
        # broken until openstack bug with marker + deleted is fixed
        returns a list of ec2 ids of all deleted instances
        (status is DELETED only, not ERROR or BUILD)
        for all tenants
        '''
        instances = {}
        opts = {'all_tenants': True, 'deleted': True, 'limit': self.limit}
        while True:
            servers = self.client.servers.list(detailed=True, search_opts=opts)
            if not servers:
                break
            for instance in servers:
                if instance.status == 'DELETED':
                    instances[getattr(
                        instance, 'OS-EXT-SRV-ATTR:instance_name')] = instance
            opts['marker'] = servers[-1].id
            time.sleep(1)
        if not instances:
            Whiner.whine("no deleted nova instances found, very fishy...",
                         fatal=True)
        return instances


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

    def __init__(self, timeout=120):
        '''
        timeout is the nuymber of seconds the
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
        return self.accepted_keys

    def get_unresponsive_hosts(self):
        '''
        returns a list of salt keys for hosts
        that do not respond to test.ping but are
        known to salt
        '''
        if self.accepted_keys is None:
            self.get_accepted_keys()

        result = self.client.cmd('*', 'test.ping', timeout=self.timeout)
        responsive = result.keys()
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


class Runner(object):
    '''
    handle action requests for display of nova instances
    or manipulation of their salt keys
    '''

    @staticmethod
    def canonicalize(hostname, region):
        '''
        convert fqdn to the short form by
        dropping the domain, if there is one

        'region' should be eqiad/pmtpa/ etc depending
        on the dc this script runs in
        '''
        domain = '.' + region + '.wmflabs'
        truncate_by = -1 * len(domain)
        if hostname.endswith(domain):
            hostname = hostname[:truncate_by]
        return hostname

    def __init__(self, actions, authfile, dryrun):
        self.actions = actions
        self.dryrun = dryrun
        self.nova_client = NovaClient(authfile)
        self.saltkeys = SaltKeys()
        self.good_instances = None
        self.bad_salt_hosts = None

    def run(self):
        '''
        actually do the actions the caller requested
        '''

        if 'missingkey' in self.actions and self.actions['missingkey']:
            self.do_missingkeys()
        if 'unresponsive' in self.actions and self.actions['unresponsive']:
            self.do_unresponsive()
        if 'cleanup' in self.actions and self.actions['cleanup']:
            self.do_cleanup()
        if 'showall' in self.actions and self.actions['showall']:
	    self.do_showall()

    def do_unresponsive(self):
        '''
        display information about undeleted nova instances
        which do not respond to salt ping but are known to salt
        '''

        if self.bad_salt_hosts is None:
            self.bad_salt_hosts = self.saltkeys.get_unresponsive_hosts()
        if not self.bad_salt_hosts:
            # nothing to do
            return

        if self.good_instances is None:
            self.good_instances = self.nova_client.get_good_instances()

        print "instances unreponsive to salt test.ping"
        print "======================================="
        for bad_key in self.bad_salt_hosts:
            canonical_name = Runner.canonicalize(
                bad_key, self.nova_client.auth.get_region())
            if canonical_name in self.good_instances:
                NovaClient.instance_display(
                    self.good_instances[canonical_name])
            else:
                print "Instance ", canonical_name, "seems to be deleted."
        print

    def do_missingkeys(self):
        '''
        display information about undeleted nova instances
        which are unknown to salt (no salt key)
        '''

        known_to_salt = self.saltkeys.get_accepted_keys()
        if not known_to_salt:
            # nothing to do
            return
        salt_canonical_names = [Runner.canonicalize(
            key, self.nova_client.auth.get_region())
            for key in known_to_salt]

        if self.good_instances is None:
            self.good_instances = self.nova_client.get_good_instances()

        print "instances with no salt key:"
        print "==========================="
        for ec2_id in self.good_instances:
            if ec2_id not in salt_canonical_names:
                NovaClient.instance_display(self.good_instances[ec2_id])
        print

    def do_showall(self):
        '''
        display information about all instances
        '''

        if self.good_instances is None:
            self.good_instances = self.nova_client.get_good_instances()

        print "all instances not deleted:"
        print "=========================="
        for ec2_id in self.good_instances:
            NovaClient.instance_display(self.good_instances[ec2_id])


    def do_cleanup(self):
        '''
        remove salt keys for deleted nova instances
        '''

        if self.bad_salt_hosts is None:
            self.bad_salt_hosts = self.saltkeys.get_unresponsive_hosts()
        if not self.bad_salt_hosts:
            # nothing to do
            return

        if self.good_instances is None:
            self.good_instances = self.nova_client.get_good_instances()

        instance_ids = self.good_instances.keys()

        log("Key deletion")
        for bad_key in self.bad_salt_hosts:
            if (Runner.canonicalize(bad_key,
                                    self.nova_client.auth.get_region())
                    not in instance_ids):
                if not self.dryrun:
                    log("About to delete key %s" % bad_key)
                    self.saltkeys.delete_bad_key(bad_key)
                else:
                    print "would delete", bad_key


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
Usage: monitor_labs_salt_keys.py <action>...
                         [--authfile] [--dryrun] [--help]

where <action> is one of --cleanup --missing --no_ping --showall

This script can, depending on the options specified, display
information about labs instances with no salt key or labs instances
unresponsive to salt, or it can delete saly keys of deleted labs
instances.

It relies on salt and on nova; it must be run on the salt master.

Options:

  --authfile (-a): path to a file of nova authentication credentials
                   see 'Authfile Format' for the contents of the file
                   default: /root/novaenv.sh
  --cleanup (-c):  cleanup salt keys of deleted instances
  --dryrun (-d):   don't delete anything, describe what would be done
  --missing (-m):  show information about instances with missing salt keys
  --no_ping (-n):  show information about instances unresponsive to salt
  --showall (-s):  show information about all undeleted instances

  --help (-h):     display this usage message

Authfile Format

The file of authentication credentials must be in the following
format (order of lines does not matter but each line must occur
someplace):

export OS_USERNAME="some-name"
export OS_PASSWORD="password-here"
export OS_AUTH_URL="http://hostname:port/vx.y"
export OS_REGION_NAME="..."
export OS_TENANT_NAME="..."

Lines with # or blank lines are skipped.
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def main():
    'main entry point, does all the work'
    authfile = '/root/novaenv.sh'
    missingkey = False
    unresponsive = False
    cleanup = False
    showall = False
    dryrun = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "a:cdmnsh",
            ["auth=", "showall", "cleanup", "missing",
             "no_ping", "dryrun", "help"])

    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))
    for (opt, val) in options:
        if opt in ["-a", "--auth"]:
            authfile = val
        elif opt in ["-c", "--cleanup"]:
            cleanup = True
        elif opt in ["-d", "--dryrun"]:
            dryrun = True
        elif opt in ["-m", "--missing"]:
            missingkey = True
        elif opt in ["-n", "--no_ping"]:
            unresponsive = True
        elif opt in ["-s", "--showall"]:
            showall = True
        elif opt in ["-h", "--help"]:
            usage('Help for this script\n')
        else:
            usage("Unknown option specified: <%s>" % opt)

    if len(remainder) > 0:
        usage("Unknown option(s) specified: <%s>" % remainder[0])

    if not cleanup and not missingkey and not unresponsive and not showall:
        usage("One of the options 'cleanup', 'missing', 'showall' or"
              "'no_ping' must be specified")

    runner = Runner({'cleanup': cleanup, 'missingkey': missingkey,
                     'unresponsive': unresponsive, 'showall': showall}, authfile, dryrun)
    runner.run()


if __name__ == '__main__':
    main()
