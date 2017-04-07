# Class: dnsrecursor
#
# [*listen_addresses]
#  Addresses the DNS recursor should listen on for queries
#
# [*allow_from]
#  Prefixes from which to allow recursive DNS queries

class dnsrecursor(
    $listen_addresses         = [$::ipaddress],
    $allow_from               = [],
    $additional_forward_zones = '',
    $auth_zones               = undef,
    $lua_hooks                = undef,
    $max_cache_entries        = 1000000,
    $max_negative_ttl         = 3600,
    $max_tcp_clients          = 128,
    $max_tcp_per_client       = 100,
    $client_tcp_timeout       = 2,
    $export_etc_hosts         = 'off',
) {

    include ::network::constants
    include ::dnsrecursor::metrics
    $forward_zones = 'wmnet=208.80.154.238;208.80.153.231;91.198.174.239, 10.in-addr.arpa=208.80.154.238;208.80.153.231;91.198.174.239'

    system::role { 'dnsrecursor':
        ensure      => 'absent',
        description => 'Recursive DNS server',
    }

    # This is to ensure we get pdns-recursor 4.x on jessie
    if os_version('debian < stretch') {
        apt::pin { 'pdns-recursor':
            package  => 'pdns-recursor',
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['pdns-recursor'],
        }
    }

    package { 'pdns-recursor':
        ensure => 'present',
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

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }
}
