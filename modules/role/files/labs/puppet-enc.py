#!/usr/bin/python3
import yaml
import sys
import ldap3
from urllib.request import urlopen


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

    if domain != 'wmflabs' and domain != 'labtest':
        return False

    if realm != 'codfw' and realm != 'eqiad':
        return False

    hostname = [x.replace('-', '').replace('_', '') for x in host_parts]

    # list of fqdn parts that are not alphanumeric should be empty
    if len([s for s in hostname if not s.isalnum()]) > 0:
        return False

    return True

if __name__ == '__main__':
    hostname = sys.argv[1]

    # check to make sure ec2id_name is an actual ec2id based hostname, to
    # prevent ldap injection attacks
    if not _is_valid_hostname(hostname):
        print('Invalid hostname', hostname)
        sys.exit(-1)

    with open('/etc/puppet-enc.yaml', encoding='utf-8') as f:
        encconfig = yaml.safe_load(f)

    with open('/etc/ldap.yaml', encoding='utf-8') as f:
        ldapconfig = yaml.safe_load(f)

    servers = ldap3.ServerPool([
        ldap3.Server(s)
        for s in ldapconfig['servers']
    ], ldap3.POOLING_STRATEGY_ROUND_ROBIN, active=True, exhaust=True)

    classes = set()

    with ldap3.Connection(
        servers,
        read_only=True,
        user=ldapconfig['user'],
        auto_bind=True,
        password=ldapconfig['password']
    ) as conn:
        conn.search(
            'ou=hosts,dc=wikimedia,dc=org',
            '(&(objectclass=puppetClient)(associatedDomain=%s))' % (hostname),
            ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
            attributes=['puppetClass'],
            time_limit=5
        )
        if len(conn.response) != 1:
            print('Exactly one match must be found for hostname ', hostname)
            print('But', len(conn.response), 'matches found')
            sys.exit(-1)

        attrs = conn.response[0]['attributes']
        classes.update(attrs.get('puppetClass', []))

    url = 'http://{host}:8100/v1/{project}/node/{fqdn}'.format(
        host=encconfig['host'],
        project=hostname.split('.')[1],
        fqdn=hostname
    )

    rest_response = yaml.safe_load(urlopen(url))

    classes.update(rest_response.get('roles', []))
    yaml.safe_dump({
        'classes': list(classes),
        'parameters': {}
    }, sys.stdout)
