# Sets up a maps server replica
class role::maps::replica {
    include profile::base::production
    include profile::rsyslog::udp_localhost_compat
    include profile::firewall

    include profile::maps::osm_replica
    include profile::prometheus::postgres_exporter
}
