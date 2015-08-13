class swift::stats::accounts(
    $swift_cluster = $::swift::params::swift_cluster,
    $accounts      = $::swift::params::accounts,
    $credentials   = $::swift::params::account_keys,
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_prefix = "swift.${::swift::params::swift_cluster}.stats",
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
        source  => 'puppet:///modules/swift/swift-account-stats',
        require => $required_packages,
    }

    $account_names = sort(keys($accounts))
    swift::stats::stats_account { $account_names:
        accounts      => $accounts,
        statsd_prefix => $statsd_prefix,
        statsd_host   => $statsd_host,
        credentials   => $credentials,
    }
}
