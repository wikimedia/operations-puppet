#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import requests
import yaml
import sys

import mwopenstackclients


def _is_valid_hostname(name):
    """
    Check that hostname is of the form:
     * <host>.(eqiad1|codfw1dev).wikimedia.cloud
     * <host>.<project>.(eqiad1|codfw1dev).wikimedia.cloud

    where host and project are alphanumeric with '-' and '_' allowed
    """
    host_parts = name.split('.')[::-1]

    tld = host_parts.pop(0)
    if tld != 'cloud':
        print('Invalid hostname ({}) Unknown TLD.'.format(name))
        return False

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
    clients = mwopenstackclients.clients(oscloud="novaobserver")
    id_for_names = {project.name: project.id for project in clients.allprojects()}
    project_name = hostname.split('.')[1]
    project_id = id_for_names[project_name]

    # check to make sure ec2id_name is an actual ec2id based hostname, to
    # prevent ldap injection attacks
    if not _is_valid_hostname(hostname):
        sys.exit(-1)

    with open('/etc/puppet-enc.yaml', encoding='utf-8') as f:
        encconfig = yaml.safe_load(f)

    classes = set()

    url = '{api_endpoint}/v1/{project_id}/node/{fqdn}'.format(
        api_endpoint=encconfig['api_endpoint'],
        project_id=project_id,
        fqdn=hostname
    )

    response = requests.get(
        url,
        headers={"User-Agent": f"enc-client {requests.utils.default_user_agent()}"},
        timeout=5,
    )
    response.raise_for_status()

    rest_response = yaml.safe_load(response.text)

    classes.update(rest_response.get('roles', []))
    yaml.safe_dump({
        'classes': sorted(list(classes)),
        'parameters': {}
    }, sys.stdout)
