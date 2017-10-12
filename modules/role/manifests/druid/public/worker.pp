# Class: role::druid::public::worker
# Sets up the Druid public cluster for use with AQS and wikistats 2.0.
#
class role::druid::public::worker {
    system::role { 'druid::public::worker':
        description => "Druid worker in the public-${::site} cluster",
    }

    include ::lvs::realserver

    include ::profile::druid::broker
    include ::profile::druid::coordinator
    include ::profile::druid::historical
    include ::profile::druid::middlemanager
    include ::profile::druid::overlord

    # Zookeeper is co-located on some public druid hosts, but not all.
    if $::fqdn in $::profile::druid::common::zookeeper_hosts {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }
}
