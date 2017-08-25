# Utilities for querying openstack
class openstack2::clientlib(
    $version,
  ) {

    $packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
        'python-designateclient',
    ]
    require_package($packages)

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => present,
        source => 'puppet:///modules/openstack2/clientlib/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # assumption is any version not liberty is newer
    # Ubuntu on liberty /does not/

    if os_version('ubuntu trusty') and $version != 'liberty' {

        $python3packages = [
            'python3-keystoneclient',
            'python3-novaclient',
            'python3-glanceclient',
        ]
        require_package($python3packages)

        file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
            ensure => present,
            source => 'puppet:///modules/openstack2/clientlib/mwopenstackclients.py',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }
}
