@monitoring::group { "maps_eqiad": description => "eqiad maps servers" }
@monitoring::group { "maps_codfw": description => "codfw maps servers" }

class role::maps::master {
    include standard
    include ::postgresql::master
    include ::postgresql::postgis
    include ::osm
    include ::osm::import_waterlines
    include ::cassandra
    include ::role::kartotherian
    include ::role::tilerator
    include ::redis

    system::role { 'role::maps::master':
        ensure      => 'present',
        description => 'Maps Postgres master',
    }

    if $::realm == 'production' {
        include lvs::realserver
    }

    postgresql::spatialdb { 'gis':
        require => Class['::postgresql::postgis'],
    }

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/postgres/tuning.conf',
    }
    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    # Replication
    $postgres_slaves = hiera('maps::postgres_slaves', undef)
    if $postgres_slaves {
        create_resources(postgresql::user, $postgres_slaves)
    }

    # Grants
    $kartotherian_pass = hiera('maps::postgresql_kartotherian_pass')
    $tilerator_pass = hiera('maps::postgresql_tilerator_pass')
    $osmimporter_pass = hiera('maps::postgresql_osmimporter_pass')
    $osmupdater_pass = hiera('maps::postgresql_osmupdater_pass')
    file { '/usr/local/bin/maps-grants.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('maps/grants.sql.erb'),
    }
    # Cassandra grants
    $cassandra_kartotherian_pass = hiera('maps::cassandra_kartotherian_pass')
    $cassandra_tilerator_pass = hiera('maps::cassandra_tilerator_pass')
    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('maps/grants.cql.erb'),
    }
}

class role::maps::slave {
    include standard
    include ::postgresql::slave
    include ::postgresql::postgis
    include ::cassandra
    include ::role::kartotherian
    include ::role::tilerator

    if $::realm == 'production' {
        include lvs::realserver
    }

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/postgres/tuning.conf',
    }
}
