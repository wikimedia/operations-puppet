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

    # Cassandra intra-node messaging
    ferm::rule { 'cassandra-intra-node':
        ensure => present,
        rule   => 'proto tcp dport 7000 saddr $RESTBASE_HOSTS ACCEPT',
    }
    # Cassandra JMX/RMI
    ferm::rule { 'cassandra-jmx-rmi':
        ensure => present,
        rule   => 'proto tcp dport 7199 saddr $RESTBASE_HOSTS ACCEPT',
    }
    # Cassandra CQL query interface
    ferm::rule { 'cassandra-cql':
        ensure => present,
        rule   => 'proto tcp dport 9042 saddr $RESTBASE_HOSTS ACCEPT',
    }
}
