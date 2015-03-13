# Class: dnsrecursor
# Parameters:
# - $listen_addresses:
#       Addresses the DNS recursor should listen on for queries
#       (default: [$::ipaddress])
# - $allow_from:
#       Prefixes from which to allow recursive DNS queries
class dnsrecursor(
    $listen_addresses = [$::ipaddress],
    $allow_from       = []
) {
    package { 'pdns-recursor':
        ensure => 'latest',
    }

    system::role { 'dnsrecursor':
        ensure      => 'absent',
        description => 'Recursive DNS server',
    }

    include network::constants

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('dnsrecursor/recursor.conf.erb'),
    }

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }

    include metrics
}
