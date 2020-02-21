# lint:ignore:wmf_styleguide
# This should be converted to a profile

# filtertags: labs-project-deployment-prep
class role::swift::stats_reporter {

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
# lint:endignore

