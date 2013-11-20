# bastion hosts
class bastionhost {
    package { [ 'irssi', 'traceroute-nanog' ]:
        ensure => absent,
    }

    package { [ 'traceroute', 'mosh']:
        ensure => present,
    }
}
