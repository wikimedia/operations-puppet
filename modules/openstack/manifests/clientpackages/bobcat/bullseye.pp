# SPDX-License-Identifier: Apache-2.0

class openstack::clientpackages::bobcat::bullseye(
) {
    $py3packages = [
        'python3-novaclient',
        'python3-glanceclient',
        'python3-keystoneauth1',
        'python3-keystoneclient',
        # Openstacksdk is needed only to ensure the patch to it is applied in order
        # once the patch is not needed can be removed
        'python3-openstacksdk',
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
