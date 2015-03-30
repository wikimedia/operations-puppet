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

    # CQL query interface monitoring (T93886)
    monitoring::service { 'cassandra-cql':
        description   => 'Cassanda CQL query interface',
        check_command => 'check_tcp!9042',
    }

    ferm::service { 'cassandra-cql-native-transport':
        proto  => 'tcp',
        port   => '9042',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'cassandra-internode-comms':
        proto  => 'tcp',
        port   => '7000',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'cassandra-jmx-monitoring':
        proto  => 'tcp',
        port   => '7199',
        srange => '$ALL_NETWORKS',
    }

}
