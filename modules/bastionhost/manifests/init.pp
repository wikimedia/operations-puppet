# bastion hosts
class bastionhost {
    package { [
        'mtr-tiny',
        'traceroute',
        'mosh',
    ]:
        ensure => present,
    }
}
