class role::maps::master {
    include standard
    include ::postgresql::master
    include ::postgresql::postgis
    include ::cassandra
    postgresql::spatialdb { 'gis':
        require => Class['::postgresql::postgis'],
    }

    system::role { 'role::maps::master':
        ensure      => 'present',
        description => 'Maps Postgres master',
    }

    $postgres_slaves = hiera('postgresql::master::postgres_slaves', undef)
    if $postgres_slaves {
        create_resources(postgresql::user, $postgres_slaves)
    }

    # Grants
    $tilerator_pass = hiera('postgresql::master::tilerator_pass')
    $osmimporter_pass = hiera('postgresql::master::osmimporter_pass')
    $osmupdater_pass = hiera('postgresql::master::osmupdater_pass')
    file { '/usr/local/bin/maps-grants.sql':
        owner => 'root',
        group => 'root',
        mode  => '0400',
        content => template('templates/maps/grants.sql.erb'),
    }
}

class role::maps::slave {
    include standard
    include ::postgresql::slave
    include ::postgresql::postgis
    include ::cassandra

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
}
