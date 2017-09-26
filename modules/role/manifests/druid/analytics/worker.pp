# Class: role::druid::analytics::worker
#
class role::druid::analytics::worker {
	include ::profile::druid::broker
	include ::profile::druid::coordinator
	include ::profile::druid::historical
	include ::profile::druid::middlemanager
	include ::profile::druid::overlord

	# Zookeeper is co-located on some analytics druid hosts, but not all.
    if $::fqdn in $::profile::druid::common::zookeeper_hosts {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }
}
