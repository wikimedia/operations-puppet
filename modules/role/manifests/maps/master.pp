# Sets up a maps server master
class role::maps::master {
    include ::standard
    include ::profile::base::firewall
    include ::role::lvs::realserver

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_master
    include ::profile::redis::master

    system::role { 'maps::master':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, redis, tilerator, kartotherian)',
    }

}

