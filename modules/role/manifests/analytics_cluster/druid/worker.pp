# == Class role::analytics_cluster::druid::worker
# For the time being, all Druid services are hosted on all druid nodes
# in the Analytics Cluster.  This may change if and when we expand
# the Druid cluster beyond 3 nodes.
#
# A colocated zookeeper cluster is also provisioned
# with this role, but only on hosts in the
# $::profile::druid::comon::zookeeper_hosts variable.
#
# Note that if /etc/hadoop/conf files exist, they will
# be added to druid daemon
#
# filtertags: labs-project-analytics
class role::analytics_cluster::druid::worker {

    # Require common druid package and configuration.
    require ::profile::druid::common

    # TLS proxy to expose a basic authn scheme for requests coming
    # from outside the analytics network (like AQS).
    require ::profile::druid::tlsproxy

    # Zookeeper is co-located on some druid hosts, but not all.
    if $::fqdn in $::profile::druid::common::zookeeper_hosts {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }

    # Auto reload daemons in labs, but not in production.
    $should_subscribe = $::realm ? {
        'labs'  => true,
        default => false,
    }

    # Druid Broker Service
    class { '::druid::broker':
        should_subscribe => $should_subscribe,
    }

    # Druid Coordinator Service
    class { '::druid::coordinator':
        should_subscribe => $should_subscribe,
    }

    # Druid Historical Service
    class { '::druid::historical':
        should_subscribe => $should_subscribe,
    }

    # Druid MiddleManager Indexing Service
    class { '::druid::middlemanager':
        should_subscribe => $should_subscribe,
    }

    # Druid Overlord Indexing Service
    class { '::druid::overlord':
        should_subscribe => $should_subscribe,
    }
}
