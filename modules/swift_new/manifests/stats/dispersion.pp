class swift_new::stats::dispersion(
    $swift_cluster = $::swift_new::params::swift_cluster,
    $statsd_host   = 'statsd.eqiad.wmnet',
    $statsd_prefix = "swift.${::swift_new::params::swift_cluster}.dispersion",
) {
    $required_packages = [
        Package['python-swiftclient'],
        Package['python-statsd'],
        Package['swift'],
    ]

    file { '/usr/local/bin/swift-dispersion-stats':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/swift_new/swift-dispersion-stats',
        require => $required_packages,
    }

    # XXX swift-dispersion-populate is not ran/initialized
    cron { 'swift-dispersion-stats':
        ensure  => 'present',
        command => "/usr/local/bin/swift-dispersion-stats --prefix ${statsd_prefix} --statsd-host ${statsd_host} 1>/dev/null",
        user    => 'root',
        hour    => '*',
        minute  => '*/15',
        require => File['/usr/local/bin/swift-dispersion-stats'],
    }
}
