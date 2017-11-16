# Sets up a maps server master
class role::maps::test::master {
    include ::standard
    include ::profile::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_master
    include ::profile::redis::master

    system::role { 'role::maps::test::master':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, redis, tilerator, kartotherian)',
    }

}

