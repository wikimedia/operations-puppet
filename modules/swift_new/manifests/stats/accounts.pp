class swift_new::stats::accounts(
    $cluster = $swift_new::params::cluster,
    $accounts = $swift_new::params::accounts,
    $statsd_host = 'statsd.eqiad.wmnet',
    $statsd_prefix = "swift.${cluster}.stats",
    $credentials = $swift_new::params_account_keys[$::site],
) {
    $required_packages = [
        Package['python-swiftclient'],
        Package['python-statsd'],
        Package['swift'],
        ]

    # report account stats to graphite
    file { '/usr/local/bin/swift-account-stats':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/swift_new/swift-account-stats',
        require => $required_packages,
    }

    $account_names = keys($accounts)
    swift_new::stats::stats_account { $account_names:
        accounts      => $accounts,
        statsd_prefix => $statsd_prefix,
        statsd_host   => $statsd_host,
        credentials   => $credentials[$::site]
    }
}
