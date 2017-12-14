#  Sets up the spiceproxy and nova-consoleauth.
#
#  When enabled, these services relay a Labs VM console to
#   a public IP.
class openstack::nova::spiceproxy::service(
    $active,
    $version,
){

    package { ['nova-spiceproxy', 'nova-consoleauth', 'spice-html5', 'websockify']:
        ensure  => 'present',
    }

    # The default spice_auto.html file doesn't support wss so won't
    #  work over https.  Add an exact duplicate of that file with
    #  a one-character change:  s/ws:/wss:/g
    file { '/usr/share/spice-html5/spice_sec_auto.html':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openstack/${version}/nova/spiceproxy/spice_sec_auto.html",
        require => Package['spice-html5'];
    }

    # XXX: no longer a current advisory?
    # These services aren't on by default, pending some
    #  security discussions.

    service { 'nova-spiceproxy':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-spiceproxy'];
    }

    service { 'nova-consoleauth':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-consoleauth'];
    }
}
