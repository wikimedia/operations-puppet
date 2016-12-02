#!/usr/bin/python3
import yaml
import sys
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
    project = hostname.split('.')[1]

    # check to make sure ec2id_name is an actual ec2id based hostname, to
    # prevent ldap injection attacks
    if not _is_valid_hostname(hostname):
        print('Invalid hostname', hostname)
        sys.exit(-1)

    with open('/etc/puppet-enc.yaml', encoding='utf-8') as f:
        encconfig = yaml.safe_load(f)

    classes = set()

    url = 'http://{host}:8100/v1/{project}/node/{fqdn}'.format(
        host=encconfig['host'],
        project=project,
        fqdn=hostname
    )

    rest_response = yaml.safe_load(urlopen(url))

    classes.update(rest_response.get('roles', []))
    yaml.safe_dump({
        'classes': sorted(list(classes)),
        'parameters': {}
    }, sys.stdout)
