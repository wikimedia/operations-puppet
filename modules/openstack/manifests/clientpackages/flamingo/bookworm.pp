# SPDX-License-Identifier: Apache-2.0

class openstack::clientpackages::flamingo::bookworm(
) {
    # these pull the right repos
    include openstack::serverpackages::flamingo::bookworm

    $py3packages = [
        'python3-novaclient',
        'python3-glanceclient',
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-openstackclient',
        'python3-troveclient',
        'python3-designateclient',
        'python3-neutronclient',
        'python3-osc-placement',
        'python3-tenacity',
    ]

    ensure_packages($py3packages + ['patch'])

    file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
