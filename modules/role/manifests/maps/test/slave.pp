# Sets up a maps server slave
class role::maps::test::slave {
    include ::standard
    include ::profile::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_slave

    system::role { 'role::maps::test::slave':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, tilerator, kartotherian)',
    }

}
