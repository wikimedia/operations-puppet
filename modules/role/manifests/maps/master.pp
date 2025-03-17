# Sets up a maps server master
class role::maps::master {
    include profile::base::production
    include profile::rsyslog::udp_localhost_compat
    include profile::firewall

    include profile::maps::osm_master
    include profile::prometheus::postgres_exporter
}
