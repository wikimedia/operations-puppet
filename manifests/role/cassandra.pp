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

    $cassandra_hosts    = hiera('restbase::cassandra::seeds')
    $cassandra_host_ips = inline_template("( <% @cassandra_hosts.each do |cassandra_host| -%><% _erbout.concat(Resolv::DNS.open.getaddress('$cassandra_host').to_s) %> <% end -%> )")

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => $cassandra_host_ips,
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto  => 'tcp',
        port   => '7199',
        srange => $cassandra_host_ips,
    }
    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => $cassandra_host_ips,
    }
}
