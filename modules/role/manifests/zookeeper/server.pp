# Classes for Zookeeper nodes.
# These role classes will configure Zookeeper properly in either
# the labs or production environments.
#
# Usage:
#
# If you only need Zookeeper client configs to talk to Zookeeper servers:
#   include role::zookeeper::client
#
# If you want to set up a Zookeeper server:
#   include role::zookeeper::server
#
# == Class role::zookeeper::server
#
# zookeeper_cluster_name in hiera will be used to make jmxtrans
# properly prefix zookeeper statsd (and graphite) metrics.
#
class role::zookeeper::server {
    include role::zookeeper::client
    $cluster_name = $::role::zookeeper::client::cluster_name

    system::role { 'role::zookeeper::server':
        description => "${cluster_name} Cluster Zookeeper Server"
    }

    class { '::zookeeper::server': }

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '($INTERNAL)',
    }

    $group_prefix = "zookeeper.cluster.${cluster_name}."
    # Use jmxtrans for sending metrics to ganglia
    class { 'zookeeper::jmxtrans':
        group_prefix => $group_prefix,
        statsd       => hiera('statsd', undef),
    }

    if $::realm == 'production' {
        # Alert if Zookeeper Server is not running.
        nrpe::monitor_service { 'zookeeper':
            description  => 'Zookeeper Server',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg"',
            critical     => true,
        }

        # jmxtrans statsd writer emits fqdns in keys
        # by substituting '.' with '_' and suffixing the jmx port.
        $graphite_broker_key = regsubst("${::fqdn}_${::zookeeper::jmxtrans::jmx_port}", '\.', '_', 'G')

        # Alert if NumAliveConnections approaches max client connections
        # Alert if any Kafka Broker replica lag is too high
        monitoring::graphite_threshold { 'zookeeper-client-connections':
            description => 'Zookeeper Alive Client Connections too high',
            metric      => "${group_prefix}zookeeper.${graphite_broker_key}.zookeeper.NumAliveConnections",
            # Warn if we go over 50% of max
            warning     => $::zookeeper::max_client_connections * 0.5,
            # Critical if we go over 90% of max
            critical    => $::zookeeper::max_client_connections * 0.9,
        }
    }
}
