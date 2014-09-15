# role/analytics/zookeeper.pp
#
# Role classes for Analytics Zookeeper nodes.
# These role classes will configure Zookeeper properly in either
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

    if $::realm == 'labs' {
        # It is difficult to to build a parameterized hash from
        # the labs wikitech console global variables.
        # Labs only supports a single zookeeper node.
        if $::zookeeper_host {
            $hosts = {
                "${::zookeeper_host}" => 1,
            }
        }
        else {
            $hosts = {}
        }
    }
    # else production
    else {
        $hosts = {
            'analytics1023.eqiad.wmnet' => 1023,
            'analytics1024.eqiad.wmnet' => 1024,
            'analytics1025.eqiad.wmnet' => 1025,
        }
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
        # Default tick_time is 2000ms, this should allow a max
        # of 16 seconds of latency for Zookeeper client sessions.
        # See comments in role::analytics::kafka::server for more info.
        sync_limit => 8,
    }
}

# == Class role::analytics::zookeeper::server
#
class role::analytics::zookeeper::server inherits role::analytics::zookeeper::client {
    system::role { 'role::analytics::zookeeper::server':
        description => 'Analytics Cluster Zookeeper Server'
    }

    class { '::zookeeper::server': }

    if ($::realm == 'labs') {
        $ganglia_host = 'aggregator.eqiad.wmflabs'
        $ganglia_port = 50090
    }
    else {
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host = '239.192.1.32'
        $ganglia_port = 8649

        # Only allow hosts in the Analytics Cluster to
        # connect to the Zookeeper admin client port.
        #
        # We don't include base::firewall yet, but do
        # want to restrict access to administrative
        # services.  We need defs.erb to be rendered
        # so we can reference defined networks in rules.
        # NOTE:  This should be removed if we get a useable
        # base::firewall class.
        include ferm
        include network::constants
        ferm::conf { 'defs':
            # defs can always be present.
            # They don't actually do firewalling.
            ensure  => 'present',
            prio    => '00',
            content => template('base/firewall/defs.erb')
        }

        ferm::service { 'zookeeper-client':
            proto  => 'tcp',
            port   => '2181',
            srange => '($ANALYTICS_NETWORKS)',
        }
    }
    # Use jmxtrans for sending metrics to ganglia
    class { 'zookeeper::jmxtrans':
        ganglia => "${ganglia_host}:${ganglia_port}",
    }
}
