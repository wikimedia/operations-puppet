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
#
# You need to include the hiera variable 'zookeeper_hosts' as a
# assoc array with key being name of node and value being zookeeper id
# for the client / server roles to work.

# == Class role::zookeeper::server
#
# Set zookeeper_cluster_name in hiera to make jmxtrans
# properly prefix zookeeper statsd (and graphite) metrics.
#
class role::zookeeper::server {
    # Lookup cluster_name from hiera with sane defaults for
    # labs and production.
    $cluster_name = hiera('zookeeper_cluster_name', $::realm ? {
        'labs'       => $::labsproject,
        'production' => $::site,
    })

    system::role { 'role::zookeeper::server':
        description => "${cluster_name} Cluster Zookeeper Server"
    }

    include role::zookeeper::client

    class { '::zookeeper::server': }

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '($INTERNAL)',
    }

    # Use jmxtrans for sending metrics to ganglia
    class { 'zookeeper::jmxtrans':
        group_prefix => "zookeeper.cluster.${cluster_name}.",
        statsd  => hiera('statsd', undef),
    }
}
