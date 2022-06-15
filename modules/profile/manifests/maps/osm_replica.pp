class profile::maps::osm_replica(
    Stdlib::Host $master     = lookup('profile::maps::osm_replica::master'),
    # check_postgres_replication_lag script relies on values that are only
    # readable by superuser or replication user. This prevents using a
    # dedicated user for monitoring.
    String $replication_pass = lookup('postgresql::slave::replication_pass'),
    Optional[Integer[250]] $log_min_duration_statement = lookup('profile::maps::osm_replica::log_min_duration_statement', { 'default_value' => undef })
){

    require ::profile::maps::postgresql_common

    $tegola_networks = flatten([
        $network::constants::services_kubepods_networks,
        $network::constants::staging_kubepods_networks,
    ])

    $pgversion = $::lsbdistcodename ? {
        'buster'  => 11,
        'stretch' => 9.6,
    }


    class { '::postgresql::slave':
        master_server              => $master,
        root_dir                   => '/srv/postgresql',
        includes                   => ['tuning.conf'],
        log_min_duration_statement => $log_min_duration_statement,
    }

    class { 'postgresql::slave::monitoring':
        pg_master   => $master,
        pg_user     => 'replication',
        pg_password => $replication_pass,
        critical    => 16777216, # 16Mb
        warning     => 2097152, # 2Mb
        retries     => 15, # compensate for spikes in lag when OSM database resync is underway.
    }

    # tegola-vector-tiles will connect as user tilerator from
    # kubernetes pods.
    $tegola_networks.each |String $subnet| {
        if $subnet =~ Stdlib::IP::Address::V4 {
            $_subnet = split($subnet, '/')[0]
            postgresql::user::hba { "${_subnet}_kubepod":
                user      => 'tilerator',
                database  => 'all',
                cidr      => $subnet,
                hba_label => "${subnet}_kubepod",
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
