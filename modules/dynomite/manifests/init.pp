# == Class: dynomite
#
# dynomite is a fast and lightweight routing proxy for memcached/redis.
# It supports sharded pools of data, replication amongst pools, as well
# as region (multi-datacenter) awareness.
#
# === Parameters
#
# [*pool*]
#   Storage pool name
#
# [*store_type]
#   Either "redis" or "memcached"
#
# [*store_servers*]
#   A hash defining the topology {<region>: {<hostname>: <token> [, ... ]} [, ... ] }
#
# [*store_port]
#   The port number to listen to the local storage server
#
# [*region*]
#   Name of the datacenter in this geographical region
#
# [*port*]
#   The port number that the dynomite service should listen on for clients
#
# [*stats_port*]
#   The port number that the dynomite stats service should listen on
#
# === Examples
#
#  class { '::dynomite':
#    pool          => 'main_cache',
#    store_type    => 'memcached',
#    store_servers => {
#      region_east => [ '10.68.24.25', '10.68.24.49' ],
#      region_west => [ '10.68.23.24', '10.68.23.49' ]
#    },
#    store_port    => 11211,
#    region        => 'region_east',
#    port          => 8101,
#    stats_port    => 22221
#  }
#
class dynomite(
    $pool,
    $store_type,
    $store_servers,
    $store_port,
    $region,
    $port,
    $stats_port,
    $ensure    = present
) {
    validate_hash($store_servers)

    require_package('dynomite')

    $store_id = $store_type ? {
        'memcached' => 1,
        'redis'     => 0,
        default     => 0
    }

    $seeds_by_region = $store_servers.map |$region, $servers| {
        $servers.map |$server, $token| {
            # Exclude the node itself from its seed list;
            # https://github.com/Netflix/dynomite/issues/423
            if ( $server == $::hostname ) {
                next()
            }
            # Prefix rack name per https://github.com/Netflix/dynomite/issues/142
            "${server}:${port}:${region}_${pool}:${region}:${token}"
        }
    }
    # Flatten the array down to an array of strings (dynomite seeds)
    $seeds = $seeds_by_region.reduce() |$memo, $value| {
        union($memo, $value)
    }

    $config = {
        datacenter   => $region,
        rack         => "${region}_${pool}",
        dyn_listen   => "127.0.0.1:${port}", # always local
        dyn_seeds    => $seeds,
        listen       => $port,
        servers      => [ "127.0.0.1:${store_port}:1" ], # always local
        tokens       => $store_servers[$region][$::hostname],
        data_store   => $store_id,
        stats_listen => "127.0.0.1:${stats_port}" # always local
    }

    file { '/etc/dynomite/config.yaml':
        ensure  => $ensure,
        content => ordered_yaml( { 'dyn_o_mite' => $config } ),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['dynomite'],
    }

    File['/etc/dynomite/config.yaml'] {
        validate_cmd => '/usr/bin/dynomite --test-conf --conf-file file:%',
    }

    $enable = $ensure ? {
        'present' => true,
        default   => false
    }

    service { 'dynomite':
        ensure => ensure_service($ensure),
        enable => $enable
    }
}