# == Class role::cassandra
#
class role::cassandra {
    # Parameters to be set by Hiera
    class { '::cassandra': }
    class { '::cassandra::metrics': }
    class { '::cassandra::logging': }

    # temporary collector, T78514
    diamond::collector { 'CassandraCollector':
        ensure => absent,
    }

    system::role { 'role::cassandra':
        description => 'Cassandra server',
    }

    nrpe::monitor_systemd_unit_state { 'cassandra':
        require => Service['cassandra'],
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { 'cassandra-cql':
        description   => 'Cassanda CQL query interface',
        check_command => 'check_tcp!9042',
        contact_group => 'admins,team-services',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto  => 'tcp',
        port   => '7199',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }
    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }

}
