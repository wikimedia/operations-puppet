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
    $additional_forward_zones = '',
    $auth_zones               = undef,
    $lua_hooks                = undef,
) {
    package { 'pdns-recursor':
        ensure => 'present',
    }

    $forward_zones    = 'wmnet=208.80.154.238;208.80.153.231;91.198.174.239, 10.in-addr.arpa=208.80.154.238;208.80.153.231;91.198.174.239'

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
        notify  => Service['pdns-recursor'],
        content => template('dnsrecursor/recursor.conf.erb'),
    }

    file { '/etc/powerdns/localhost.zone':
        ensure  => 'present',
        require => Package['dns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/dnsrecursor/localhost.zone',
    }

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf'],
                      File['/etc/powerdns/localhost.zone']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }

    if $lua_hooks {
        file { '/etc/powerdns/recursorhooks.lua':
            ensure  => 'present',
            require => Package['pdns-recursor'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service['pdns-recursor'],
            content => template('dnsrecursor/recursorhooks.lua.erb'),
        }
    }

    include metrics
}
