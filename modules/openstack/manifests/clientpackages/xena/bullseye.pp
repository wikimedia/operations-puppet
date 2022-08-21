# SPDX-License-Identifier: Apache-2.0

class openstack::clientpackages::xena::bullseye(
) {
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
    ]

    package{ $py3packages:
        ensure => 'present',
    }

    $otherpackages = [
        'ebtables',
    ]

    package { $otherpackages:
        ensure => 'present',
    }

    file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients3.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
