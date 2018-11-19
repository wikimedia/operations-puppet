# Utilities for querying openstack
class openstack::clientlib(
    $version,
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

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientlib/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Functions to create or delete designate domains under .wmflabs.org
    file { '/usr/lib/python2.7/dist-packages/designatemakedomain.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientlib/designatemakedomain.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    if os_version('debian jessie') and $version == 'liberty' {

        $debian_jessie_packages = [
            'python-keystoneauth1',
        ]

        package{ $debian_jessie_packages:
            ensure => 'present',
        }
    }

    if os_version('debian stretch') and $version == 'newton' {
        $python3packages = [
            'python3-keystoneauth1',
            'python3-keystoneclient',
            'python3-novaclient',
            'python3-glanceclient',
            'python3-openstackclient',
            'python3-designateclient',
            'python3-neutronclient',
        ]

        package{ $python3packages:
            ensure => 'present',
        }
    }

    # assumption is any version not liberty is newer
    # Ubuntu on liberty /does not/
    if os_version('ubuntu trusty') and $version != 'liberty' {

        $python3packages = [
            'python3-keystoneclient',
            'python3-novaclient',
            'python3-glanceclient',
        ]

        package{ $python3packages:
            ensure => 'present',
        }

        file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
            ensure => 'present',
            source => 'puppet:///modules/openstack/clientlib/mwopenstackclients.py',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }
}
