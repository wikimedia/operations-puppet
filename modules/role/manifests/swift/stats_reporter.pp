class role::swift::stats_reporter {
    system::role { 'role::swift::stats_reporter':
        description => 'swift statistics reporter',
    }

    include standard
    include ::swift::params
    include ::swift::stats::dispersion
    include ::swift::stats::accounts

    swift::stats::stats_container { 'mw-media':
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_prefix => "swift.${::swift::params::swift_cluster}.containers.mw-media",
    }
}

