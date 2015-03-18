#!/usr/bin/python
import re
import yaml
import sys
import ldapsupportlib
import ldap
import os
import flask
import time


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

# These are globals. How do they work? I am not fully sure,
# but they seem to?
roles_rulesets = {}


def roles_rules_for(project_name):
    path = os.path.join('/var/lib/git/operations/puppet/nodes/labs/',
                        project_name + '.yaml')
    if project_name not in roles_rulesets:
        if os.path.exists(path):
            with open(path) as f:
                rules = YAMLRolesRules(yaml.load(f))
        else:
            rules = EmptyRolesRules()
        roles_rulesets[project_name] = (int(time.time()), rules)
        return rules

    if os.stat(path).st_mtime > roles_rulesets[project_name][0]:
        del roles_rulesets[project_name]
        return roles_rules_for(project_name)
    else:
        return roles_rulesets[project_name][1]

app = flask.Flask(__name__)
ldapConn = ldapsupportlib.LDAPSupportLib().connect()

@app.route('/roles_for/<string:ec2id_hostname>')
def roles_for(ec2id_hostname):

    # check to make sure ec2id_name is an actual ec2id based hostname, to prevent
    # ldap injection attacks
    if not re.match(r'^[a-zA-Z0-9_-]+\.eqiad\.wmflabs$', ec2id_hostname):
        print 'Invalid hostname', ec2id_hostname
        sys.exit(-1)
    query = 'dc=%s' % (ec2id_hostname)
    base = 'ou=hosts,dc=wikimedia,dc=org'
    result = ldapConn.search_s(base, ldap.SCOPE_SUBTREE, query)
    if result:
        host_info = result[0][1]
        roles = host_info['puppetClass']
        puppetvars = {
            var[0]: var[1]
            for var in [pv.split("=") for pv in host_info['puppetVar']]
        }

        roles_rules = roles_rules_for(puppetvars['instanceproject'])
        roles += roles_rules.roles_for(puppetvars['instancename'])
        return yaml.dump({
            'classes': roles,
            'parameters': puppetvars,
        })

if __name__ == '__main__':
    app.run(debug=True)
