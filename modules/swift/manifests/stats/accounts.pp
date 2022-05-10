class swift::stats::accounts(
    String $swift_cluster,
    Hash[String, Hash] $accounts,
    Hash[String, String] $credentials,
    Wmflib::Ensure $ensure = present,
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_port   = 8125,
    $statsd_prefix = "swift.${swift_cluster}.stats",
) {
    $required_packages = [
        Package['python3-swiftclient'],
        Package['python3-statsd'],
        Package['swift'],
        ]

    # report account stats to graphite
    file { '/usr/local/bin/swift-account-stats':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/${module_name}/swift-account-stats.py",
        require => $required_packages,
    }

    file { '/usr/local/bin/swift-account-stats-timer.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/swift/swift-account-stats-timer.sh'
    }

    # report container stats to graphite
    file { '/usr/local/bin/swift-container-stats':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/${module_name}/swift-container-stats.py",
        require => $required_packages,
    }

    file { '/usr/local/bin/swift-container-stats-timer.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/swift/swift-container-stats-timer.sh'
    }

    $account_names = sort(keys($accounts))
    swift::stats::stats_account { $account_names:
        ensure        => $ensure,
        accounts      => $accounts,
        statsd_prefix => $statsd_prefix,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
        credentials   => $credentials,
    }
}
