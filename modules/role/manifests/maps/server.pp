# This role class sets up a maps server with
# the services kartotherian and tilerator
class role::maps::server {
    include standard
    include ::postgresql::postgis
    include ::cassandra
    include ::cassandra::metrics
    include ::cassandra::logging
    include ::kartotherian
    include ::tilerator

    # Not the right place for this, but let's check if it is working first and
    # see how to integrate this cleanly in the cassandra module next
    file { '/srv/cassandra':
        owner => 'cassandra',
        group => 'cassandra',
    }

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
        source => 'puppet:///modules/role/maps/tuning.conf',
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
    # TODO: Is that really true? Since CQL 3.0 it should not be. Revisit
    ferm::service { 'cassandra-cql-thrift':
        proto  => 'tcp',
        port   => '9160',
        srange => "(${cassandra_hosts_ferm})",
    }

    # NOTE: Kartotherian, tilerator, tileratorui get their ferm rules via
    # service::node. That is an exception from our rules but it was deemed OK
}
