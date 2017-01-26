#  Sets up the spiceproxy and nova-consoleauth.
#
#  When enabled, these services relay a Labs VM console to
#   a public IP.
class openstack::nova::spiceproxy(
    $openstack_version=$::openstack::version,
){
    include ::openstack::repo

    package { ['nova-spiceproxy', 'nova-consoleauth', 'spice-html5', 'websockify']:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    # The default spice_auto.html file doesn't support wss so won't
    #  work over https.  Add an exact duplicate of that file with
    #  a one-character change:  s/ws:/wss:/g
    file { '/usr/share/spice-html5/spice_sec_auto.html':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openstack/${openstack_version}/nova/spice_sec_auto.html",
        require => Package['spice-html5'];
    }

    if $::fqdn == hiera('labs_nova_controller') {
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
            ensure  => stopped,
            require => Package['nova-spiceproxy'];
        }
        service { 'nova-consoleauth':
            ensure  => stopped,
            require => Package['nova-consoleauth'];
        }
    }
}
