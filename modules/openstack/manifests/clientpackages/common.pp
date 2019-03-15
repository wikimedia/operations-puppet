class openstack::clientpackages::common(
) {
    $pypackages = [
        'python-novaclient',
        'python3-novaclient',
        'python-glanceclient',
        'python3-glanceclient',
        'python-keystoneclient',
        'python3-keystoneclient',
        'python3-keystoneauth1',
        'python-openstackclient',
        'python3-openstackclient',
        'python-designateclient',
        'python3-designateclient',
        'python-neutronclient',
        'python3-neutronclient',
    ]

    package { $pypackages:
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
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Functions to create or delete designate domains under .wmflabs.org
    file { '/usr/lib/python2.7/dist-packages/designatemakedomain.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/designatemakedomain.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
