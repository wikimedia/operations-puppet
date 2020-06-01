class swift::expirer (
    $ensure,
    $statsd_host               = undef,
    $statsd_port               = 8125,
    $statsd_metric_prefix      = undef,
    $statsd_sample_rate_factor = '1',
    $memcached_servers         = ['127.0.0.1:11211'],
) {
    package { 'swift-object-expirer':
        ensure => $ensure,
    }

    file { '/etc/swift/object-expirer.conf':
        ensure  => $ensure,
        content => template('swift/object-expirer.conf.erb'),
        owner   => 'swift',
        group   => 'swift',
        mode    => '0440',
        require => Package['swift-object-expirer'],
    }

    service { 'swift-object-expirer':
        ensure => ensure_service($ensure),
    }
}
