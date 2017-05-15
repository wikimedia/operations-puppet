class swift::stats::dispersion(
    $swift_cluster = $::swift::params::swift_cluster,
    $storage_policies = $::swift::params::storage_policies,
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_prefix = "swift.${::swift::params::swift_cluster}.dispersion",
) {
    $required_packages = [
        Package['python-swiftclient'],
        Package['python-statsd'],
        Package['swift'],
    ]

    file { '/usr/local/bin/swift-dispersion-stats':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/swift/swift-dispersion-stats',
        require => $required_packages,
    }

    # XXX swift-dispersion-populate is not ran/initialized
    cron { 'swift-dispersion-stats':
        ensure  => present,
        command => "/usr/local/bin/swift-dispersion-stats --prefix ${statsd_prefix} --statsd-host ${statsd_host} >/dev/null 2>&1",
        user    => 'root',
        hour    => '*',
        minute  => '*/15',
        require => File['/usr/local/bin/swift-dispersion-stats'],
    }

    if $storage_policies {
        cron { 'swift-dispersion-stats':
            ensure  => present,
            command => "/usr/local/bin/swift-dispersion-stats --prefix ${statsd_prefix}.lowlatency --statsd-host ${statsd_host} --policy-name lowlatency >/dev/null 2>&1",
            user    => 'root',
            hour    => '*',
            minute  => '*/15',
            require => File['/usr/local/bin/swift-dispersion-stats'],
        }
    }
}
