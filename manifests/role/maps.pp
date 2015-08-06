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

    if $::realm == 'production' {
        include lvs::realserver
    }

    postgresql::spatialdb { 'gis':
        require => Class['::postgresql::postgis'],
    }

    system::role { 'role::maps::master':
        ensure      => 'present',
        description => 'Maps Postgres master',
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
    $postgres_slaves = hiera('postgresql::master::postgres_slaves', undef)
    if $postgres_slaves {
        create_resources(postgresql::user, $postgres_slaves)
    }

    # Grants
    $kartotherian_pass = hiera('postgresql::master::kartotherian_pass')
    $tilerator_pass = hiera('postgresql::master::tilerator_pass')
    $osmimporter_pass = hiera('postgresql::master::osmimporter_pass')
    $osmupdater_pass = hiera('postgresql::master::osmupdater_pass')
    file { '/usr/local/bin/maps-grants.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('maps/grants.sql.erb'),
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
}
