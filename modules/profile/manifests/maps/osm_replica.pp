# SPDX-License-Identifier: Apache-2.0
class profile::maps::osm_replica(
    Stdlib::Host $master                               = lookup('profile::maps::osm_replica::master'),
    # check_postgres_replication_lag script relies on values that are only
    # readable by superuser or replication user. This prevents using a
    # dedicated user for monitoring.
    String $replication_pass                           = lookup('profile::maps::osm_master::replication_pass'),
    Boolean                   $use_replication_slots   = lookup('profile::maps::osm_replica::use_replication_slots'),
    Optional[Integer[250]] $log_min_duration_statement = lookup('profile::maps::osm_replica::log_min_duration_statement', { 'default_value' => undef })
){

    require profile::maps::postgresql_common

    $wikikube_networks = flatten([
        $network::constants::services_kubepods_networks,
        $network::constants::staging_kubepods_networks,
    ])

    $pgversion  = Integer(wmflib::debian_postgresql_version())

    $replication_slot_name = $use_replication_slots ? {
        true    => "wal_${facts['networking']['fqdn'].regsubst('\.', '_', 'G')}",
        default => undef,
    }

    class { '::postgresql::slave':
        master_server              => $master,
        replication_pass           => $replication_pass,
        root_dir                   => '/srv/postgresql',
        includes                   => ['tuning.conf'],
        max_wal_senders            => 20, # Needs to be identical for master/replica role
        log_min_duration_statement => $log_min_duration_statement,
        replication_slot_name      => $replication_slot_name,
    }

    class { 'postgresql::slave::monitoring':
        pg_master   => $master,
        pg_user     => 'replication',
        pg_password => $replication_pass,
        critical    => 16777216, # 16Mb
        warning     => 2097152, # 2Mb
        retries     => 15, # compensate for spikes in lag when OSM database resync is underway.
    }

    $wikikube_networks.each |String $subnet| {
        if $subnet =~ Stdlib::IP::Address::V4 {
            $_subnet = split($subnet, '/')[0]
            postgresql::user::hba { "tegola_${_subnet}_kubepod":
                user      => 'tegola',
                database  => 'all',
                cidr      => $subnet,
                pgversion => $pgversion,
            }
            postgresql::user::hba { "kartotherian_${_subnet}_kubepod":
                user      => 'kartotherian',
                database  => 'gis',
                cidr      => $subnet,
                pgversion => $pgversion,
            }
        }
    }

    $prometheus_command = "/usr/bin/prometheus_postgresql_replication_lag -m ${master} -P ${replication_pass}"
    systemd::timer::job { 'prometheus-pg-replication-lag':
        ensure      => 'present',
        description => 'Postgresql replication lag to Prometheus metrics',
        command     => $prometheus_command,
        user        => 'root',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:*:00'},
    }
}
