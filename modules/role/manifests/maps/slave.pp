# Sets up a maps server slave
class role::maps::slave {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver

    include ::profile::maps::apps
    include ::profile::maps::cassandra
    include ::profile::maps::osm_slave
}
