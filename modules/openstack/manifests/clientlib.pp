# Utilities for querying openstack
class openstack::clientlib {
    include openstack::observerenv

    $packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
    ]
    require_package($packages)

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => present,
        source => 'puppet:///modules/openstack/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
