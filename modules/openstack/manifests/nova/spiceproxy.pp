#  Sets up the spiceproxy and nova-consoleauth.
#
#  When enabled, these services relay a Labs VM console to
#   a public IP.
class openstack::nova::spiceproxy {
    include openstack::repo

    package { ['nova-spiceproxy', 'nova-consoleauth', 'spice-html5', 'websockify']:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    #if $::fqdn == hiera('labs_nova_controller') {
    if false {
        # These services aren't on by default, pending some
        #  security discussions.
        service { 'nova-spiceproxy':
            ensure    => running,
            subscribe => File['/etc/nova/nova.conf'],
            require   => Package['nova-spiceproxy'];
        }

        service { 'nova-consoleauth':
            ensure    => running,
            subscribe => File['/etc/nova/nova.conf'],
            require   => Package['nova-consoleauth'];
        }
    } else {
        service { 'nova-spiceproxy':
            ensure    => stopped,
            require   => Package['nova-spiceproxy'];
        }
        service { 'nova-consoleauth':
            ensure    => stopped,
            require   => Package['nova-consoleauth'];
        }
    }
}
