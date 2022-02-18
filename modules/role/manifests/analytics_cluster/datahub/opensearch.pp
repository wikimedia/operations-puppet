class role::analytics_cluster::datahub::opensearch {
    system::role { 'analytics_cluster::datahub::opensearch':
        description => 'Opensearch cluster powering datahub'
    }

    include ::profile::base::production
    include ::profile::opensearch::server
    include ::profile::rsyslog::udp_json_logback_compat
}
