# filtertags: labs-project-deployment-prep
class role::swift::stats_reporter {
    system::role { 'swift::stats_reporter':
        description => 'swift statistics reporter',
    }

    include ::profile::standard
    include ::swift::params
    include ::swift::stats::dispersion
    include ::swift::stats::accounts

    swift::stats::stats_container { 'mw-media':
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_prefix => "swift.${::swift::params::swift_cluster}.containers.mw-media",
        statsd_host   => hiera('swift::stats_reporter::statsd_host', 'statsd.eqiad.wmnet'),
        statsd_port   => hiera('swift::stats_reporter::statsd_port', '8125'),
    }
}

