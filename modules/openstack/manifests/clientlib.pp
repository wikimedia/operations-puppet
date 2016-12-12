# Utilities for querying openstack
class openstack::clientlib {

    # We don't need all the extras that role::labs::openstack::nova::common
    #  includes... the simple config straight from hiera should do the trick.
    $novaconfig = hiera_hash('novaconfig', {})
    $nova_region = $::site

    $packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
    ]
    require_package($packages)

    # Handy script to set up environment for read-only credentials
    file { '/usr/local/bin/observerenv.sh':
        content => template('openstack/observerenv.sh.erb'),
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
    }

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => present,
        source => 'puppet:///modules/openstack/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
