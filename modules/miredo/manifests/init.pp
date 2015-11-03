# Miredo is a Teredo client (as per RFC 4380)
# Teredo is IPv6 tunneling
# https://packages.debian.org/jessie/miredo
class miredo {

    package { 'miredo':
        ensure    => installed,
    }

    file { '/etc/miredo.conf':
        owner   => root,
        group   => root,
        mode    => '0444',
        require => Package['miredo'],
        source  => 'puppet:///modules/miredo/miredo.conf',
    }

    service { 'miredo':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        require   => Package['miredo'],
        subscribe => File['/etc/miredo.conf'],
    }
}
