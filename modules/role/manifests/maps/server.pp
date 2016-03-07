# This role class sets up a maps server with
# the services kartotherian and tilerator
class role::maps::server {
    include standard
    include ::postgresql::postgis
    include ::cassandra
    include ::kartotherian
    include ::tilerator

    system::role { 'role::maps':
        description => 'A vector and raster map tile generation service',
    }

    ganglia::plugin::python { 'diskstat': }

    if $::realm == 'production' {
        include lvs::realserver
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
    # TODO: Figure out a better way to do this
    # Ensure postgresql logs as maps-admin to allow maps-admin to read them
    # Rely on logrotate's copytruncate policy for postgres for the rest of the
    # log file
    file { '/var/log/postgresql/postgresql-9.4-main.log':
        group => 'maps-admins',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'maps-cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => "(${cassandra_hosts_ferm})",
    }

    # Cassandra JMX/RMI
    ferm::service { 'maps-cassandra-jmx-rmi':
        proto  => 'tcp',
        # hardcoded limit of 4 instances per host
        port   => '7199',
        srange => "(${cassandra_hosts_ferm})",
    }

    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "(${cassandra_hosts_ferm})",
    }

    # Cassandra Thrift interface, used by cqlsh
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9160',
        srange => "(${cassandra_hosts_ferm})",
    }

    # Kartotherian
    ferm::service { 'kartotherian':
        proto   => 'tcp',
        port    => '6533',
        srange  => '$INTERNAL',
    }

    # Tilerator
    ferm::service { 'tilerator':
        proto   => 'tcp',
        port    => '6534',
        srange  => '$INTERNAL',
    }

    # TileratorUI
    ferm::service { 'tileratorui':
        proto   => 'tcp',
        port    => '6535',
        srange  => '$INTERNAL',
    }
}

# Sets up a maps server master
class role::maps::master {
    include ::postgresql::master
    include ::osm
    include ::osm::import_waterlines

    redis::instance { 6379: }

    system::role { 'role::maps::master':
        ensure      => 'present',
        description => 'Maps Postgres master',
    }

    # DB passwords
    $kartotherian_pass = hiera('maps::postgresql_kartotherian_pass')
    $tilerator_pass = hiera('maps::postgresql_tilerator_pass')
    $tileratorui_pass = hiera('maps::postgresql_tileratorui_pass')
    $osmimporter_pass = hiera('maps::postgresql_osmimporter_pass')
    $osmupdater_pass = hiera('maps::postgresql_osmupdater_pass')

    # Db setup
    postgresql::spatialdb { 'gis':
        require => Class['::postgresql::postgis'],
    }

    # PostgreSQL Replication
    $postgres_slaves = hiera('maps::postgres_slaves', undef)
    if $postgres_slaves {
        create_resources(postgresql::user, $postgres_slaves)
    }

    osm::planet_sync { 'gis':
        ensure        => present,
        flat_nodes    => true,
        expire_levels => '16',
        num_threads   => 4,
        pg_password   => $osmupdater_pass,
        period        => 'day', # Remove thse as soon as we get down to minute
        hour          => '1',
        minute        => '27',
    }

    # Grants
    file { '/usr/local/bin/maps-grants.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('maps/grants.sql.erb'),
    }
    # Cassandra grants
    $cassandra_kartotherian_pass = hiera('maps::cassandra_kartotherian_pass')
    $cassandra_tilerator_pass = hiera('maps::cassandra_tilerator_pass')
    $cassandra_tileratorui_pass = hiera('maps::cassandra_tileratorui_pass')
    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('maps/grants.cql.erb'),
    }
}

# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
}
