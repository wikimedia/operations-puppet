# == Class role::cassandra
#
class role::cassandra {
    # Parameters to be set by Hiera
    class { '::cassandra': }
    class { '::cassandra::metrics': }

    system::role { 'role::cassandra':
        description => 'Cassandra server',
    }

    # Emit an Icinga alert unless there is exactly one Java process belonging
    # to user 'cassandra' and with 'CassandraDaemon' in its argument list.
    nrpe::monitor_service { 'cassandra':
        description  => 'Cassandra database',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u cassandra -C java -a CassandraDaemon',
    }

    # get cassandra host names from hiera
    #$host_names = hiera('hosts')
    #$cassandra_hosts = $host_names[1]['hostname']

    $cassandra_hosts = '(10.64.0.220 10.64.0.221 10.64.32.159 10.64.32.160 10.64.48.99 10.64.48.100 10.64.16.147 10.64.0.200 10.64.16.149)'

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => $cassandra_hosts,
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto  => 'tcp',
        port   => '7199',
        srange => $cassandra_hosts,
    }
    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => $cassandra_hosts,
    }
}
