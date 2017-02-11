# == Class role::aqs
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.
# Each AQS node has both colocated.
#
# filtertags: labs-project-deployment-prep
class role::aqs {
    system::role { 'role::aqs':
        description => 'Analytics Query Service Node',
    }

    include ::passwords::aqs

    include ::standard
    include ::base::firewall

    #
    # Set up Cassandra for AQS.
    #

    # Parameters to be set by Hiera
    include ::cassandra
    include ::cassandra::metrics
    include ::cassandra::logging

    $cassandra_instances = $::cassandra::instances

    if $cassandra_instances {
        $instance_names = keys($cassandra_instances)
        ::cassandra::instance::monitoring { $instance_names:
            contact_group => 'admins,team-services,analytics',
        }
    } else {
        $default_instances = {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
            }
        }
        ::cassandra::instance::monitoring { 'default':
            instances     => $default_instances,
            contact_group => 'admins,team-services,analytics',
        }
    }

    $cassandra_hosts_ferm = join(hiera('cassandra::seeds'), ' ')

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

    # In addition to the IP assigned to the Cassandra multi instances, these rules
    # grant access from the actual AQS hosts
    $aqs_hosts_ferm = join(hiera('aqs_hosts'), ' ')

    # Cassandra CQL query interface
    ferm::service { 'cassandra-analytics-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "(@resolve((${cassandra_hosts_ferm})) @resolve((${aqs_hosts_ferm})) ${analytics_networks})",
    }

    #
    # Set up AQS
    #

    include ::aqs
    include ::aqs::monitoring

    include role::lvs::realserver

    ferm::service {'aqs_web':
        proto => 'tcp',
        port  => $::aqs::port,
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
