class swift::stats::accounts(
    $swift_cluster = undef,
    $accounts      = {},
    $credentials   = {},
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_prefix = "swift.${swift_cluster}.stats",
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
        source  => "puppet:///modules/${module_name}/swift-account-stats",
        require => $required_packages,
    }

    # report container stats to graphite
    file { '/usr/local/bin/swift-container-stats':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/${module_name}/swift-container-stats",
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
