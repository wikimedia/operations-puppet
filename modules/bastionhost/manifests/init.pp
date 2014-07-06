# bastion hosts
class bastionhost {
    system::role { 'bastionhost':
        description => 'Bastion',
    }

    package { [ 'irssi', 'traceroute-nanog' ]:
        ensure => absent,
    }

    package { 'traceroute':
        ensure =>latest,
    }

    package { 'mosh':
        ensure => present,
    }
}
