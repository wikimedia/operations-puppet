# Utilities for querying openstack
class openstack::observerenv {

    # We don't need all the extras that role::labs::openstack::nova::common
    #  includes... the simple config straight from hiera should do the trick.
    $novaconfig = hiera_hash('novaconfig', {})
    $nova_region = $::site

    # Keystone credentials for novaobserver
    file { '/etc/novaobserver.yaml':
        content => template('openstack/novaobserver.yaml.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/bin/observerenv.sh':
        source => 'puppet:///modules/openstack/observerenv.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
