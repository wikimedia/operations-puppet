# lint:ignore:wmf_styleguide
# This should be converted to a profile

# filtertags: labs-project-deployment-prep
class role::swift::stats_reporter {
    $swift_cluster = lookup('profile::swift::cluster')
    $accounts = lookup('profile::swift::accounts')
    $credentials = lookup('profile::swift::accounts_keys')

    include ::profile::standard

    class { '::swift::stats::dispersion':
        swift_cluster => $swift_cluster,
    }

    class { '::swift::stats::accounts':
        swift_cluster => $swift_cluster,
        accounts      => $accounts,
        credentials   => $credentials,
    }

    swift::stats::stats_container { 'mw-media':
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_prefix => "swift.${swift_cluster}.containers.mw-media",
        statsd_host   => hiera('swift::stats_reporter::statsd_host', 'statsd.eqiad.wmnet'),
        statsd_port   => hiera('swift::stats_reporter::statsd_port', '8125'),
    }
}
# lint:endignore
