# Class: dnsrecursor
# Parameters:
# - $listen_addresses:
#       Addresses the DNS recursor should listen on for queries
#       (default: [$::ipaddress])
# - $allow_from:
#       Prefixes from which to allow recursive DNS queries
class dnsrecursor(
    $listen_addresses         = [$::ipaddress],
    $allow_from               = [],
    $ip_aliases               = undef,
    $additional_forward_zones = "",
    $auth_zones               = undef
) {
    package { 'pdns-recursor':
        ensure => 'present',
    }

    $forward_zones    = "wmnet=208.80.154.238;208.80.153.231;91.198.174.239, 10.in-addr.arpa=208.80.154.238;208.80.153.231;91.198.174.239"

    system::role { 'dnsrecursor':
        ensure      => 'absent',
        description => 'Recursive DNS server',
    }

    include network::constants

    $alias_script='/etc/powerdns/ip-alias.lua'
    if $ip_aliases {
        file { $alias_script:
            ensure  => present,
            require => Package['pdns-recursor'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service['pdns-recursor'],
            content => template('dnsrecursor/ip-alias.lua.erb'),
        }
    } else {
        file { $alias_script:
            ensure  => absent,
        }
    }

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pdns-recursor'],
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
