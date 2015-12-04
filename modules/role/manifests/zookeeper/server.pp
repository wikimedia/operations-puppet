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
class role::zookeeper::server {
    system::role { 'role::zookeeper::server':
        description => 'Analytics Cluster Zookeeper Server'
    }

    include role::zookeeper::client

    class { '::zookeeper::server': }

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '($INTERNAL)',
    }

    if $::standard::has_ganglia {
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host = '208.80.154.10'
        $ganglia_port = 9690

        # Use jmxtrans for sending metrics to ganglia
        class { 'zookeeper::jmxtrans':
            ganglia => "${ganglia_host}:${ganglia_port}",
        }
    }
}
