# == Class role::cassandra
#
# filtertags: labs-project-deployment-prep
class role::cassandra {
    include ::passwords::cassandra
    include ::base::firewall

    # Parameters to be set by Hiera
    class { '::cassandra': }
    class { '::cassandra::metrics': }
    class { '::cassandra::logging': }
    class { '::cassandra::twcs': }

    class { '::cassandra::sysctl':
        # Queue page flushes at 24MB intervals
        vm_dirty_background_bytes => 25165824,
    }

    $cassandra_instances = $::cassandra::instances

    if $cassandra_instances {
        $instance_names = keys($cassandra_instances)
        ::cassandra::instance::monitoring{ $instance_names: }
    } else {
        $default_instances = {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
        }}
        ::cassandra::instance::monitoring{ 'default':
            instances => $default_instances,
        }
    }

    # temporary collector, T78514
    diamond::collector { 'CassandraCollector':
        ensure => absent,
    }

    system::role { 'role::cassandra':
        description => 'Cassandra server',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

    $prometheus_nodes = hiera('prometheus_nodes')
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Cassandra intra-node SSL messaging
    ferm::service { 'cassandra-intra-node-ssl':
        proto  => 'tcp',
        port   => '7001',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto  => 'tcp',
        # hardcoded limit of 4 instances per host
        port   => '7199:7202',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Prometheus jmx_exporter for Cassandra
    ferm::service { 'cassandra-jmx_exporter':
        proto  => 'tcp',
        port   => '7800',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }

}
