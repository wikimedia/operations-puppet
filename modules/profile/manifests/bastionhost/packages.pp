# packages installed on bastion hosts
class profile::bastionhost::packages {
    package { [
        'mtr-tiny',
        'traceroute',
        'mosh',
    ]:
        ensure => present,
    }
}
