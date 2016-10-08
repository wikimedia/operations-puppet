class profile::swift::stats_reporter {
    # Global variables
    # These variables are most probably defined in the common hierarchy.
    $graphite_host = hiera('graphite_host', 'graphite-in.eqiad.wmnet')
    $statsd_host = hiera('statsd_host', 'statsd.eqiad.wmnet')
    $app_routes = hiera('discovery::app_routes')

    # Swift-wide variables
    # Typically defined in {common,$site}/swift.yaml
    $cluster_name = hiera('swift::cluster', "${::site}-prod")
    $swift_frontends = hiera('swift::proxyhosts')
    $accounts = hiera('swift::accounts')
    $account_keys = hiera('swift::account_keys')

    class { '::swift::stats::dispersion':
        swift_cluster => $cluster_name,
        statsd_host   => $statsd_host,
        statsd_prefix => "swift.${cluster_name}.dispersion",
    }

    class { '::swift::stats::accounts':
        swift_cluster => $cluster_name,
        accounts      => $accounts,
        statsd_host   => $statsd_host,
        statsd_prefix => "swift.${cluster_name}.stats",
    }

    swift::stats::stats_container { 'mw-media':
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_prefix => "swift.${cluster_name}.containers.mw-media",
    }
}
