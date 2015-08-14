# == Class role::cassandra-analytics
#
class role::analytics::cassandra {
    # Parameters to be set by Hiera
    include ::cassandra
    include ::cassandra::metrics
    include ::cassandra::logging

    system::role { 'role::cassandra-analytics':
        description => 'Analytics Cassandra server',
    }

    # Emit an Icinga alert unless there is exactly one Java process belonging
    # to user 'cassandra' and with 'CassandraDaemon' in its argument list.
    nrpe::monitor_service { 'cassandra-analytics':
        description  => 'Analytics Cassandra database',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u cassandra -C java -a CassandraDaemon',
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { 'cassandra-analytics-cql':
        description   => 'Analytics Cassanda CQL query interface',
        check_command => 'check_tcp!9042',
        contact_group => 'admins,analytics',
    }

    $cassandra_hosts = hiera('cassandra::seeds')
    $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-analytics-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-analytics-jmx-rmi':
        proto  => 'tcp',
        port   => '7199',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }
    # Cassandra CQL query interface
    ferm::service { 'cassandra-analytics-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "@resolve(($cassandra_hosts_ferm))",
    }

}
