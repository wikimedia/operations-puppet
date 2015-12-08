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


def _guess_and_convert_type(value):
    """
    Guess at the type of value passed in and convert appropriately

    This does a subset of the thing that LDAP's node terminator does,
    in that it does not support floats, only integers.
    See https://phabricator.wikimedia.org/T95240#1187339 for rationale

    :param value: string value to convert
    :return: string value converted to number or boolean as appropriate
    """
    if value == 'true':
        return True
    if value == 'false':
        return False
    if value.isdigit():
        return int(value)
    return value


def _is_valid_hostname(name):
    """
    Check that hostname is of the form <host>.(eqiad|codfw).wmflabs or
    <host>.<project>.(eqiad|codfw).wmflabs

    where host and project are alphanumeric with '-' and '_' allowed
    """
    host_parts = name.split('.')[::-1]

    if len(host_parts) > 4 or len(host_parts) < 3:
        return False

    domain = host_parts.pop(0)
    realm = host_parts.pop(0)

    if domain != 'wmflabs':
        return False

    if realm != 'codfw' and realm != 'eqiad':
        return False

    hostname = [x.replace('-', '').replace('_', '') for x in host_parts]

    # list of fqdn parts that are not alphanumeric should be empty
    if len([s for s in hostname if not s.isalnum()]) > 0:
        return False

    return True

if __name__ == '__main__':
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

    # check to make sure ec2id_name is an actual ec2id based hostname, to
    # prevent ldap injection attacks
    if not _is_valid_hostname(ec2id_name):
        print 'Invalid hostname', ec2id_name
        sys.exit(-1)
    query = '(&(objectclass=puppetClient)(associatedDomain=%s))' % (ec2id_name)
    base = 'ou=hosts,dc=wikimedia,dc=org'
    result = ldapConn.search_s(base, ldap.SCOPE_SUBTREE, query)
    if result:
        roles = ['role::labs::instance']
        host_info = result[0][1]
        try:
            roles += host_info['puppetClass']
        except KeyError:
            pass
        puppetvars = {
            var[0]: _guess_and_convert_type(var[1])
            for var in [pv.split("=") for pv in host_info['puppetVar']]
        }
        roles += rolesrules.roles_for(puppetvars['instancename'])
        yaml.dump({
            'classes': roles,
            'parameters': puppetvars,
        }, sys.stdout)
