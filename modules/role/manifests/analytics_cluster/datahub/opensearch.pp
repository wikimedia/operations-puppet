class role::analytics_cluster::datahub::opensearch {
    include profile::base::production
    include profile::firewall
    include profile::opensearch::datahubsearch
    include profile::rsyslog::udp_json_logback_compat
    include profile::opensearch::monitoring::base_checks
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
