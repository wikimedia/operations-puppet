class swift::proxy (
    $proxy_service_host,
    $shard_container_list,
    $accounts = $swift::params::accounts,
    $credentials = $swift::params::account_keys,
    $memcached_servers         = ['127.0.0.1:11211'],
    $statsd_host               = undef,
    $statsd_port               = 8125,
    $statsd_metric_prefix      = undef,
    $statsd_sample_rate_factor = '1',
    $bind_port                 = '80',
    $num_workers               = $::processorcount,
    $rewrite_account           = undef,
    $dispersion_account        = undef,
    $thumborhost               = '',
    $inactivedc_thumborhost    = '',
) {
    package {[
        'swift-proxy',
        'python-eventlet',
    ]:
        ensure => present,
    }

    file { '/etc/swift/proxy-server.conf':
        owner   => 'swift',
        group   => 'swift',
        mode    => '0440',
        content => template('swift/proxy-server.conf.erb'),
        require => Package['swift-proxy'],
    }

    if $dispersion_account != undef {
        file { '/etc/swift/dispersion.conf':
            owner   => 'swift',
            group   => 'swift',
            mode    => '0440',
            content => template('swift/dispersion.conf.erb'),
            require => Package['swift'],
        }
    }

    logrotate::conf { 'swift-proxy':
        ensure => absent,
    }

    rsyslog::conf { 'swift-proxy':
        ensure   => absent,
    }

    # stock Debian package uses start-stop-daemon --chuid and init.d script to
    # start swift-proxy, our proxy binds to port 80 so it isn't going to work.
    # Use a modified version of 'swift-proxy' systemd unit
    systemd::service { 'swift-proxy':
        content => systemd_template('swift-proxy'),
    }

    file { '/usr/local/lib/python2.7/dist-packages/wmf/':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/swift/SwiftMedia/wmf/',
        recurse => 'remote',
    }
}
