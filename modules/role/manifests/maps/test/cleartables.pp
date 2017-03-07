# Sets up a maps server master
class role::maps::test::cleartables {
    include ::standard
    include ::base::firewall

    include ::profile::maps::osm_master
}
