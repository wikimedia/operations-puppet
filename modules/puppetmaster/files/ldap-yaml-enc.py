import re
import yaml
from collections import OrderedDict
import sys
import ldapsupportlib
import ldap
import os


def ordered_load(stream):
    """
    Load an ordered dict from a given yaml stream
    :return: a yaml document where dicts retain their ordering
    """
    class OrderedLoader(yaml.SafeLoader):
        pass

    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return OrderedDict(loader.construct_pairs(node))
    OrderedLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
        construct_mapping)
    return yaml.load(stream, OrderedLoader)


class RolesRules(object):
    """
    A set of rules that help map a hostname to a set of roles.
    """
    def __init__(self, rules):
        self.rules = {
            re.compile(key): value
            for key, value in rules.items()
        }

    def roles_for(self, instancename):
        """
        Return list of roles for given instancename
        """
        matched_roles = []
        for check, roles in self.rules.items():
            if check.match(instancename):
                matched_roles += roles

        return matched_roles


with open('/etc/wmflabs-project') as f:
    path = os.path.join('/var/lib/git/operations/production/nodes/labs/',
                        f.readall().strip())

with open(path) as f:
    rolesrules = RolesRules(ordered_load(f))

ldapConn = ldapsupportlib.LDAPSupportLib().connect()

ec2id_name = sys.argv[1]
query = 'dc=%s' % (ec2id_name)
base = 'ou=hosts,dc=wikimedia,dc=org'
result = ldapConn.search_s(base, ldap.SCOPE_SUBTREE, query)
if result:
    host_info = result[0][1]
    roles = host_info['puppetClass']
    puppetvars = {
        var[0]: var[1]
        for var in [pv.split("=") for pv in host_info['puppetVar']]
    }
    roles += rolesrules.roles_for(puppetvars['instancename'])
    yaml.dump({
        'classes': roles,
        'parameters': puppetvars,
    }, sys.stdout)
