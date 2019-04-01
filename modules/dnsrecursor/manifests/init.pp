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
    $version_hostname         = false,
) {

    include ::network::constants
    $wmf_authdns = [
        '208.80.154.238',
        '208.80.153.231',
        '91.198.174.239',
    ]
    $wmf_authdns_semi = join($wmf_authdns, ';')
    $forward_zones = "wmnet=${wmf_authdns_semi}, 10.in-addr.arpa=${wmf_authdns_semi}"

    # systemd unit fragment to raise ulimits
    $sysd_dir = '/etc/systemd/system/pdns-recursor.service.d'
    $sysd_frag = "${sysd_dir}/ulimits.conf"

    file { $sysd_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $sysd_frag:
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dnsrecursor/ulimits.conf',
    }

    exec { "systemd reload for ${sysd_frag}":
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$sysd_frag],
        before      => Service['pdns-recursor'],
    }

    if os_version('debian == jessie') {
        # jessie uses backports for v4
        apt::pin { 'pdns-recursor':
            package  => 'pdns-recursor',
            pin      => 'release a=openstack-mitaka-jessie',
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
