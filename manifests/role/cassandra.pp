# == Class role::cassandra
#
class role::cassandra {
    include ::passwords::cassandra
    include base::firewall

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

    # Emit an Icinga alert unless there is exactly one Java process belonging
    # to user 'cassandra' and with 'CassandraDaemon' in its argument list.
    nrpe::monitor_service { 'cassandra':
        description  => 'Cassandra database',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u cassandra -C java -a CassandraDaemon',
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { 'cassandra-cql':
        description   => 'Cassandra CQL query interface',
        check_command => 'check_tcp!9042',
        contact_group => 'admins,team-services',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

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

}
