# Sets up a maps server replica
class role::maps::replica {
    include ::profile::standard
    include ::profile::rsyslog::udp_localhost_compat
    include ::profile::base::firewall
    include ::profile::lvs::realserver

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_replica
    include ::profile::maps::tlsproxy
    include ::profile::prometheus::postgres_exporter

    system::role { 'maps::replica':
      ensure      => 'present',
      description => 'Maps replica (postgresql, cassandra, tilerator, kartotherian)',
    }

}
