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


# == Class role::analytics::zookeeper::client
#
class role::analytics::zookeeper::client {
    # include common labs or production zookeeper configs
    # based on $::realm
    if ($::realm == 'labs') {
        include role::analytics::zookeeper::labs
    }
    else {
        include role::analytics::zookeeper::production
    }
}

class role::analytics::zookeeper::server inherits role::analytics::zookeeper::client {
    class { '::zookeeper::server': }
}


# == Class role::analytics::zookeeper::production
#
class role::analytics::zookeeper::production {
    $zookeeper_hosts = {
        'analytics1023.eqiad.wmnet' => 23,
        'analytics1024.eqiad.wmnet' => 24,
        'analytics1025.eqiad.wmnet' => 25,
    }

    class { '::zookeeper':
        hosts   => $zookeeper_hosts,
        version => '3.3.5+dfsg1-1ubuntu1',
    }
}

# == Class role::analytics::zookeeper::labs
#
class role::analytics::zookeeper::labs {
    $zookeeper_hosts = {
        'kraken-puppet.pmtpa.wmflabs' => 1,
    }

    class { '::zookeeper':
        hosts   => $zookeeper_hosts,
        version => '3.3.5+dfsg1-1ubuntu1',
    }
}
