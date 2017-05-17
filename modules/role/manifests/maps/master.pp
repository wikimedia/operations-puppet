# Sets up a maps server master
class role::maps::master(
    $planet_sync_period = 'day', # Remove this as soon as we get down to minute
    $planet_sync_hour = '1',
    $planet_sync_minute = '27',
    $postgres_tile_storage = false,
) {
    include ::postgresql::master
    include ::role::maps::postgresql_common
    include ::osm
    include ::osm::import_waterlines

    system::role { 'maps::master':
        ensure      => 'present',
        description => 'Maps Postgres master',
    }
    redis::instance { '6379':
        settings => { 'bind' => '0.0.0.0' },
    }

    # DB passwords
    $kartotherian_pass = hiera('maps::postgresql_kartotherian_pass')
    $tilerator_pass = hiera('maps::postgresql_tilerator_pass')
    $tileratorui_pass = hiera('maps::postgresql_tileratorui_pass')
    $osmimporter_pass = hiera('maps::postgresql_osmimporter_pass')
    $osmupdater_pass = hiera('maps::postgresql_osmupdater_pass')
    $replication_pass = hiera('maps::postgresql_replication_pass')
    $postgres_slaves = hiera('maps::postgres_slaves', undef)

    # Users
    postgresql::user { 'kartotherian':
        user     => 'kartotherian',
        password => $kartotherian_pass,
        database => 'gis',
    }

    role::maps::tilerator_user { 'localhost':
        ip_address => '127.0.0.1',
        password   => $tilerator_pass,
    }

    if $postgres_slaves {
        create_resources(
            role::maps::tilerator_user,
            $postgres_slaves,
            { password => $tilerator_pass }
        )
    }

    postgresql::user { 'tileratorui':
        user     => 'tileratorui',
        password => $tileratorui_pass,
        database => 'gis',
    }
    postgresql::user { 'osmimporter':
        user     => 'osmimporter',
        password => $osmimporter_pass,
        database => 'gis',
    }
    postgresql::user { 'osmupdater':
        user     => 'osmupdater',
        password => $osmupdater_pass,
        database => 'gis',
    }

    # Grants
    file { '/usr/local/bin/maps-grants-gis.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/maps/grants-gis.sql.erb'),
    }
    file { '/usr/local/bin/maps-grants-tiles.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/maps/grants-tiles.sql.erb'),
    }

    # DB setup
    postgresql::spatialdb { 'gis': }

    if $postgres_tile_storage {
        ::postgresql::db { 'tiles':
            owner   => 'tilerator',
            require => Postgresql::User['tilerator@localhost'],
        }
    }


    # some additional logging for the postgres master to help diagnose import
    # performance issues
    file { '/etc/postgresql/9.4/main/logging.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/role/maps/logging.conf',
    }

    file { '/usr/local/bin/osm-initial-import':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/role/maps/osm-initial-import',
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

    osm::planet_sync { 'gis':
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

    class { 'osm::prometheus':
        state_path      => '/srv/osmosis/state.txt',
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Cassandra grants
    $cassandra_kartotherian_pass = hiera('maps::cassandra_kartotherian_pass')
    $cassandra_tilerator_pass = hiera('maps::cassandra_tilerator_pass')
    $cassandra_tileratorui_pass = hiera('maps::cassandra_tileratorui_pass')
    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/maps/grants.cql.erb'),
    }

    # Ferm rules
    $maps_hosts = hiera('maps::hosts')
    $maps_hosts_ferm = join($maps_hosts, ' ')

    ferm::service { 'tilerator_redis':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${maps_hosts_ferm}))",
    }

    # Access to postgres master from postgres slaves
    ferm::service { 'postgres_maps':
        proto  => 'tcp',
        port   => '5432',
        srange => "@resolve((${maps_hosts_ferm}))",
    }
}

