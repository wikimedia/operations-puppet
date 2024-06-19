# Class: role::druid::analytics::worker
# Sets up the Druid analytics cluster for internal use.
# This cluster may contain data not suitable for
# use in public APIs.
#
class role::druid::test_analytics::worker {
    include profile::base::production
    include profile::firewall
    include profile::java
    include profile::druid::broker
    include profile::druid::coordinator
    include profile::druid::historical
    include profile::druid::middlemanager
    include profile::druid::overlord
    include profile::prometheus::druid_exporter

    include profile::kerberos::keytabs
    include profile::kerberos::client

    # Zookeeper is co-located on some analytics druid hosts, but not all.
    if $::fqdn in $::profile::druid::common::zookeeper_hosts {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }
}
