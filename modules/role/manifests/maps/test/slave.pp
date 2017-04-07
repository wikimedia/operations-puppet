# Sets up a maps server slave
class role::maps::test::slave {
    include ::standard
    include ::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_slave
}
