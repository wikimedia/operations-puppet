# Sets up a maps server master
class role::maps::master {
    include ::postgresql::master
    include ::role::maps::postgresql_common
    include ::osm
    include ::osm::import_waterlines

    system::role { 'role::maps::master':
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

    # Users
    postgresql::user { 'kartotherian':
        ensure   => present,
        password => $kartotherian_pass,
        database => 'gis',
    }
    postgresql::user { 'tilerator':
        ensure   => present,
        password => $tilerator_pass,
        database => 'gis',
    }
    postgresql::user { 'tileratorui':
        ensure   => present,
        password => $tileratorui_pass,
        database => 'gis',
    }
    postgresql::user { 'osmimporter':
        ensure   => present,
        password => $osmimporter_pass,
        database => 'gis',
    }
    postgresql::user { 'osmupdater':
        ensure   => present,
        password => $osmupdater_pass,
        database => 'gis',
    }


    # Grants
    file { '/usr/local/bin/maps-grants.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/maps/grants.sql.erb'),
    }

    # Db setup
    postgresql::spatialdb { 'gis':
        require => Class['::postgresql::postgis'],
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

    # PostgreSQL Replication
    $postgres_slaves = hiera('maps::postgres_slaves', undef)
    if $postgres_slaves {
        create_resources(postgresql::user, $postgres_slaves)
    }

    osm::planet_sync { 'gis':
        ensure        => present,
        flat_nodes    => true,
        expire_levels => '15',
        num_threads   => 4,
        pg_password   => $osmupdater_pass,
        period        => 'day', # Remove thse as soon as we get down to minute
        hour          => '1',
        minute        => '27',
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

