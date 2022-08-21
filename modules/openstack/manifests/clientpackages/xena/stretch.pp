# SPDX-License-Identifier: Apache-2.0

class openstack::clientpackages::xena::stretch(
) {
    $py2packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
        'python-designateclient',
        'python-neutronclient',
    ]

    package{ $py2packages:
        ensure => 'present',
    }

    $py3packages = [
        'python3-novaclient',
        'python3-glanceclient',
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-openstackclient',
        'python3-designateclient',
        'python3-neutronclient',
        'python3-troveclient',
    ]

    package{ $py3packages:
        ensure => 'present',
    }

    $otherpackages = [
        'ebtables',
        'python-netaddr',
    ]

    package { $otherpackages:
        ensure => 'present',
    }

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients3.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
