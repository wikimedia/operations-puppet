class swift::stats::dispersion(
    String $swift_cluster,
    Wmflib::Ensure $ensure = present,
    Boolean $storage_policies = true,
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_port   = 8125,
    $statsd_prefix = "swift.${swift_cluster}.dispersion",
) {
    $required_packages = [
        Package['python3-swiftclient'],
        Package['python3-statsd'],
        Package['swift'],
    ]

    file { '/usr/local/bin/swift-dispersion-stats':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/swift/swift-dispersion-stats.py',
        require => $required_packages,
    }

    # XXX swift-dispersion-populate is not ran/initialized
    cron { 'swift-dispersion-stats':
        ensure  => $ensure,
        command => "/usr/local/bin/swift-dispersion-stats --prefix ${statsd_prefix} --statsd-host ${statsd_host} --statsd-port ${statsd_port} >/dev/null 2>&1",
        user    => 'root',
        hour    => '*',
        minute  => '*/15',
        require => File['/usr/local/bin/swift-dispersion-stats'],
    }

    if $storage_policies {
        cron { 'swift-dispersion-stats-lowlatency':
            ensure  => $ensure,
            command => "/usr/local/bin/swift-dispersion-stats --prefix ${statsd_prefix}.lowlatency --statsd-host ${statsd_host} --statsd-port ${statsd_port} --policy-name lowlatency >/dev/null 2>&1",
            user    => 'root',
            hour    => '*',
            minute  => '*/15',
            require => File['/usr/local/bin/swift-dispersion-stats'],
        }
    }
}
