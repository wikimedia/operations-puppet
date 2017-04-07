# Sets up a maps server master
class role::maps::test::master {
    include ::standard
    include ::base::firewall

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_master
    include ::profile::maps::redis
}

