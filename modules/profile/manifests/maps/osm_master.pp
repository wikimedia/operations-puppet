class profile::maps::osm_master {
    $planet_sync_period = hiera('profile::maps::osm_master::planet_sync_period', 'day')
    $planet_sync_hour = hiera('profile::maps::osm_master::planet_sync_hour', '1')
    $planet_sync_minute = hiera('profile::maps::osm_master::planet_sync_minute', '27')

    $maps_hosts = hiera('profile::maps::hosts')
    $maps_hosts_ferm = join($maps_hosts, ' ')

    # passwords
    $kartotherian_pass = hiera('profile::maps::osm_master::kartotherian_pass')
    $tilerator_pass = hiera('profile::maps::osm_master::tilerator_pass')
    $tileratorui_pass = hiera('profile::maps::osm_master::tileratorui_pass')
    $osmimporter_pass = hiera('profile::maps::osm_master::osmimporter_pass')
    $osmupdater_pass = hiera('profile::maps::osm_master::osmupdater_pass')
    $replication_pass = hiera('profile::maps::osm_master::replication_pass')

    $postgres_slaves = hiera('profile::maps::osm_master::slaves', undef)

    $cleartables = hiera('profile::maps::osm_master::cleartables', false)

    $db_name = $cleartables ? {
        true    => 'ct',
        default => 'gis',
    }

    require ::profile::maps::postgresql_common

    class { '::postgresql::master':
        pgversion           => '9.4',
        root_dir            => '/srv/postgresql',
        includes            => [ 'tuning.conf', 'logging.conf' ],
        checkpoint_segments => 768,
        wal_keep_segments   => 768,
    }
    include ::osm
    include ::osm::import_waterlines

    system::role { 'profile::maps::postgresql_master':
        ensure      => 'present',
        description => 'Maps Postgres master',
    }

    # Users
    postgresql::user { 'kartotherian':
        user     => 'kartotherian',
        password => $kartotherian_pass,
        database => $db_name,
    }
    postgresql::user { 'tileratorui':
        user     => 'tileratorui',
        password => $tileratorui_pass,
        database => $db_name,
    }
    postgresql::user { 'osmimporter':
        user     => 'osmimporter',
        password => $osmimporter_pass,
        database => $db_name,
    }
    postgresql::user { 'osmupdater':
        user     => 'osmupdater',
        password => $osmupdater_pass,
        database => $db_name,
    }

    profile::maps::tilerator_user { 'localhost':
        ip_address => '127.0.0.1',
        password   => $tilerator_pass,
    }

    if $postgres_slaves {
        create_resources(
            profile::maps::tilerator_user,
            $postgres_slaves,
            { password => $tilerator_pass }
        )
    }

    # Grants
    file { "/usr/local/bin/maps-grants-${db_name}.sql":
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants-gis.sql.erb'),
    }
    file { '/usr/local/bin/maps-grants-tiles.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants-tiles.sql.erb'),
    }

    # DB setup
    postgresql::spatialdb { $db_name: }

    if $cleartables {
        postgresql::db::extension { "${title}-fuzzystrmatch":
            ensure   => $ensure,
            database => $db_name,
            extname  => 'fuzzystrmatch',
            require  => Postgresql::Db[$db_name],
        }
        postgresql::db::extension { "${title}-unaccent":
            ensure   => $ensure,
            database => $db_name,
            extname  => 'unaccent',
            require  => Postgresql::Db[$db_name],
        }
    }


    # some additional logging for the postgres master to help diagnose import
    # performance issues
    file { '/etc/postgresql/9.4/main/logging.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/maps/logging.conf',
    }

    file { '/usr/local/bin/osm-initial-import':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/maps/osm-initial-import',
    }

    if $postgres_slaves {
        $postgres_slaves_defaults = {
            replication_pass => $replication_pass,
        }
        create_resources(postgresql::slave_users, $postgres_slaves, $postgres_slaves_defaults)
    }

    sudo::user { 'tilerator-notification':
        user       => 'osmupdater',
        privileges => [
            'ALL = (tileratorui) NOPASSWD: /usr/local/bin/notify-tilerator',
        ],
    }

    if $cleartables {
        osm::cleartables_sync { $db_name:
            ensure                => present,
            pg_password           => $osmupdater_pass,
            hour                  => $planet_sync_hour,
            minute                => $planet_sync_minute,
            postreplicate_command => 'sudo -u tileratorui /usr/local/bin/notify-tilerator',
        }
    } else {
        osm::planet_sync { $db_name:
            ensure                => present,
            flat_nodes            => true,
            expire_levels         => '15',
            num_threads           => 4,
            pg_password           => $osmupdater_pass,
            period                => $planet_sync_period,
            hour                  => $planet_sync_hour,
            minute                => $planet_sync_minute,
            postreplicate_command => 'sudo -u tileratorui /usr/local/bin/notify-tilerator',
        }
    }

    class { 'osm::prometheus':
        state_path      => '/srv/osmosis/state.txt',
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Access to postgres master from postgres slaves
    ferm::service { 'postgres_maps':
        proto  => 'tcp',
        port   => '5432',
        srange => "@resolve((${maps_hosts_ferm}))",
    }

}
