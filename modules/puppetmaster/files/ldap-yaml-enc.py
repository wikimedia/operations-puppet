#!/usr/bin/python
import re
import yaml
import sys
import ldapsupportlib
import ldap
import os


class EmptyRolesRules(object):
    def __init__(self):
        pass

    def roles_for(self, fqdn):
        return []


class YAMLRolesRules(object):
    """
    A set of rules that help map a hostname to a set of roles.
    """
    def __init__(self, rules):
        self.rules = {
            re.compile(key): value
            for key, value in rules.items()
        }

    def roles_for(self, fqdn):
        """
        Return list of roles for given instancename
        """
        matched_roles = []
        for check, roles in self.rules.items():
            if check.match(fqdn):
                matched_roles += roles

        return matched_roles


with open('/etc/wmflabs-project') as f:
    path = os.path.join('/var/lib/git/operations/puppet/nodes/labs/',
                        f.read().strip() + '.yaml')

if os.path.exists(path):
    with open(path) as f:
        rolesrules = YAMLRolesRules(yaml.load(f))
else:
    rolesrules = EmptyRolesRules()

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
