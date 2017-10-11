# Sets up a maps server slave
class role::maps::slave {
    include ::standard
    include ::profile::base::firewall
    include ::role::lvs::realserver

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_slave

    system::role { 'maps::slave':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, tilerator, kartotherian)',
    }

}
