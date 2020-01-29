#!/usr/bin/python3
import yaml
import sys
from urllib.request import urlopen


def _is_valid_hostname(name):
    """
    Check that hostname is of the form:
     * <host>.(eqiad|codfw).wmflabs
     * <host>.<project>.(eqiad|codfw).wmflabs
     * <host>.(eqiad1|codfw1dev).wikimedia.cloud
     * <host>.<project>.(eqiad1|codfw1dev).wikimedia.cloud

    where host and project are alphanumeric with '-' and '_' allowed
    """
    host_parts = name.split('.')[::-1]

    # this must be either 'wmflabs' or 'cloud'
    tld = host_parts.pop(0)
    if tld != 'wmflabs' and tld != 'cloud':
        print('Invalid hostname ({}) Unknown TLD.'.format(name))
        return False

    if tld == 'wmflabs':
        # current / legacy FQDN case
        # this must be either eqiad or codfw
        realm = host_parts.pop(0)
        if realm != 'eqiad' and realm != 'codfw':
            print('Invalid hostname ({}) Unknown realm.'.format(name))
            return False

    if tld == 'cloud':
        # new domain case
        # must be wikimedia.cloud
        wikimedia = host_parts.pop(0)
        if wikimedia != 'wikimedia':
            print('Invalid hostname ({}) Unknown domain.'.format(name))
            return False

        # must be deployment name, either eqiad1 or codfw1dev
        deployment = host_parts.pop(0)
        if deployment != 'eqiad1' and deployment != 'codfw1dev':
            print('Invalid hostname ({}) Unknown deployment (outdated script?).'.format(name))
            return False

    hostname = [x.replace('-', '').replace('_', '') for x in host_parts]
    # list of fqdn parts that are not alphanumeric should be empty
    if len([s for s in hostname if not s.isalnum()]) > 0:
        print('Invalid hostname ({}) Invalid characters found.'.format(name))
        return False

    return True


if __name__ == '__main__':
    hostname = sys.argv[1]
    project = hostname.split('.')[1]

    # check to make sure ec2id_name is an actual ec2id based hostname, to
    # prevent ldap injection attacks
    if not _is_valid_hostname(hostname):
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
