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

# == Class role::zookeeper::client
#
class role::zookeeper::client {

    $version = $::lsbdistcodename ? {
        'jessie'  => '3.4.5+dfsg-2',
        'trusty'  => '3.4.5+dfsg-1',
        'precise' => '3.3.5+dfsg1-1ubuntu1',
    }

    $hosts = hiera('zookeeper_hosts')

    require_package('openjdk-7-jdk')
    class { '::zookeeper':
        hosts      => $hosts,
        version    => $version,
        # Default tick_time is 2000ms, this should allow a max
        # of 16 seconds of latency for Zookeeper client sessions.
        # See comments in role::kafka::analytics::server for more info.
        sync_limit => 8,
    }
}

