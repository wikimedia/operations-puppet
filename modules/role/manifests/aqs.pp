# == Class role::aqs
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.
# Each AQS node is has both colocated.
#
class role::aqs {
    system::role { 'role::aqs':
        description => 'Analytics Query Service Node',
    }

    include standard
    include base::firewall

    #
    # Set up Cassandra for AQS.
    #

    # Parameters to be set by Hiera
    include ::cassandra
    include ::cassandra::metrics
    include ::cassandra::logging

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
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Cassandra JMX/RMI
    ferm::service { 'cassandra-analytics-jmx-rmi':
        proto  => 'tcp',
        port   => '7199',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }
    # Allow analytics networks to populate cassandra
    include network::constants
    $analytics_networks = join($network::constants::analytics_networks, ' ')
    # Cassandra CQL query interface
    ferm::service { 'cassandra-analytics-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "(@resolve((${cassandra_hosts_ferm})) ${analytics_networks})",
    }


    #
    # Set up RESTBase for AQS
    #

    include ::restbase
    include ::restbase::monitoring

    include lvs::realserver

    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => $::restbase::port,
    }

    #TODO: add monitoring once we figure out what metrics we want
    #monitoring::graphite_threshold { 'restbase_analytics_<<some-metric-name>>':
        #description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
        #metric        => '<<the metric and any transformations>>',
        #from          => '10min',
        #warning       => '<<warning threshold>>', # <<explain>>
        #critical      => '<<critical threshold>>', # <<explain>>
        #percentage    => '20',
        #contact_group => 'aqs-admins',
    #}
}
