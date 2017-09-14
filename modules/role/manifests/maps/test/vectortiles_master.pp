# Sets up a maps server master
class role::maps::test::vectortiles_master {
    include ::standard
    include ::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_master
    include ::profile::redis::master

    system::role { 'role::maps::test::master':
      ensure      => 'present',
      description => 'Maps master with vector tiles (postgresql, cassandra, redis, tilerator, kartotherian)',
    }

}

