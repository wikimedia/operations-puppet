class swift_new::proxy (
    $proxy_address,
    $rewrite_thumb_server,
    $shard_container_list,
    $accounts = $swift_new::params::accounts,
    $credentials = $swift_new::params::account_keys,
    $memcached_servers         = ['localhost:11211'],
    $statsd_host               = undef,
    $statsd_metric_prefix      = undef,
    $statsd_sample_rate_factor = '1',
    $bind_port                 = '80',
    $num_workers               = $::processorcount,
    $backend_url_format        = 'sitelang',
    $rewrite_account           = undef,
    $dispersion_account        = undef,
) {
    package {[
        'swift-proxy',
        'python-swauth',
    ]:
        ensure => present,
    }

    file { '/etc/swift/proxy-server.conf':
        owner   => 'swift',
        group   => 'swift',
        mode    => '0440',
        content => template('swift_new/proxy-server.conf.erb'),
        require => Package['swift-proxy'],
    }

    if $dispersion_account != undef {
        file { '/etc/swift/dispersion.conf':
            owner   => 'swift',
            group   => 'swift',
            mode    => '0440',
            content => template('swift_new/dispersion.conf.erb'),
            require => Package['swift'],
        }
    }

    file { '/etc/logrotate.d/swift-proxy':
        ensure => present,
        source => 'puppet:///modules/swift_new/swift-proxy.logrotate.conf',
        mode   => '0444',
    }

    rsyslog::conf { 'swift-proxy':
        source   => 'puppet:///modules/swift_new/swift-proxy.rsyslog.conf',
        priority => 30,
    }

    file { '/usr/local/lib/python2.7/dist-packages/wmf/':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        # XXX exception :(
        # this still lives in files/ to avoid code duplication
        source  => 'puppet:///files/swift/SwiftMedia/wmf/',
        recurse => 'remote',
    }
}
