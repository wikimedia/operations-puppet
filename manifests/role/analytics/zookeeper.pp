# role/analytics/zookeeper.pp
#
# Role classes for Analytics Zookeeper nodes.
# These role classes will configure Zooekeeper properly in either
# the Analytics labs or Analytics production environments.
#
# Usage:
#
# If you only need Zookeeper client configs to talk to Zookeeper servers:
#   include role::analytics::zookeeper::client
#
# If you want to set up a Zookeeper server:
#   include role::analytics::zookeeper::server
#

# == Class role::analytics::zookeeper::config
# Bare config role class for client and server classes.
# You may include this class manually if you need to know use the 
# $role::analytics::zookeeper::hosts or
# $role::analytics::zookeeper::hosts_array variables.
#
class role::analytics::zookeeper::config {
    # TODO: Make this configurable via labs
    # global variables.
    $labs_hosts = {
         'kraken-puppet.pmtpa.wmflabs' => 1,
    }

    $production_hosts = {
        'analytics1023.eqiad.wmnet' => 23,
        'analytics1024.eqiad.wmnet' => 24,
        'analytics1025.eqiad.wmnet' => 25,
    }

    $hosts = $::realm ? {
        'labs'       => $labs_hosts,
        'production' => $production_hosts,
    }

    # maintain a $hosts_array variable here for
    # cases where you need a list of zookeeper hosts,
    # rather than a hash with ZK IDs.  (This is used
    # in role/analytics/hive.pp, for example.)
    $hosts_array = keys($hosts)
}


# == Class role::analytics::zookeeper::client
#
class role::analytics::zookeeper::client {
    require role::analytics::zookeeper::config

    class { '::zookeeper':
        hosts   => $role::analytics::zookeeper::config::hosts,
        version => '3.3.5+dfsg1-1ubuntu1',
    }
}

class role::analytics::zookeeper::server inherits role::analytics::zookeeper::client {
    class { '::zookeeper::server': }
}
