# This role class sets up a maps server with
# the services kartotherian and tilerator
class role::maps::server {
    include ::standard
    include ::base::firewall
    include ::cassandra
    include ::cassandra::metrics
    include ::cassandra::logging
    include ::tilerator

    ::cassandra::instance::monitoring{ 'default':
        instances => {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
            }
        },
    }

    $cassandra_hosts = hiera('cassandra::seeds')

    # Stick with nodejs 4.6, kartotherian isn't ready for node 6 yet
    $node_version = hiera('maps::node_version', 4)

    $node_package_version = $node_version ? {
        6       => '6.9.1~dfsg-1',
        default => '4.6.0~dfsg-1+wmf2',
    }

    package { 'nodejs':
        ensure => $node_package_version,
    }

    # Some of the following parameters should be externalized in hiera as
    # common parameters shared by multiple roles. For example, statsd or
    # logstash configuration should not be specific to maps.
    # Introducting global parameters is a potentially disruptive change, so it
    # will be implemented in a specific change.
    class { 'kartotherian':
        cassandra_servers           => $cassandra_hosts,
        cassandra_kartotherian_pass => hiera('maps::cassandra_kartotherian_pass'),
        pgsql_kartotherian_pass     => hiera('maps::postgresql_kartotherian_pass'),
    }

    system::role { 'role::maps':
        description => 'A vector and raster map tile generation service',
    }

    ganglia::plugin::python { 'diskstat': }

    if $::realm == 'production' {
        include ::lvs::realserver
    }

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
