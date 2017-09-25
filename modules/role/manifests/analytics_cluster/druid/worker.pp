# == Class role::analytics_cluster::druid::worker
# For the time being, all Druid services are hosted on all druid nodes
# in the Analytics Cluster.  This may change if and when we expand
# the Druid cluster beyond 3 nodes.
#
# A colocated zookeeper cluster is also provisioned
# with this role, but only on hosts in the
# $::profile::druid::common::zookeeper_hosts variable.
#
# Note that if /etc/hadoop/conf files exist, they will
# be added to druid daemon
#
# filtertags: labs-project-analytics
class role::analytics_cluster::druid::worker {

    # Require common druid package and configuration.
    require ::profile::druid::common

    # Configure all the daemons
    include ::profile::druid::worker

    # Zookeeper is co-located on some druid hosts, but not all.
    if $::fqdn in $::profile::druid::common::zookeeper_hosts {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }
}
