# bastion hosts
class bastionhost {
    package { [ 'irssi', 'traceroute-nanog' ]:
        ensure => 'absent',
    }

    package { 'traceroute':
        ensure => 'latest',
    }

    package { 'mosh':
        ensure => 'present',
    }
}
