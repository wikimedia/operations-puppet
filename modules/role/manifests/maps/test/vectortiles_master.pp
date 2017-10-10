# Sets up a maps server master
# lint:ignore:wmf_styleguide
class role::maps::test::vectortiles_master {
    include ::standard
    # TODO: move to profile::base::firewall once https://gerrit.wikimedia.org/r/#/c/383519/ is merged
    include ::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_master
    include ::profile::redis::master

    system::role { 'role::maps::test::vectortiles_master':
      ensure      => 'present',
      description => 'Maps master (postgresql, cassandra, redis, tilerator, kartotherian)',
    }

}
