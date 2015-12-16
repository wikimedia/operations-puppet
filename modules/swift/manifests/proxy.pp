class swift::proxy (
    $proxy_service_host,
    $rewrite_thumb_server,
    $shard_container_list,
    $accounts = $swift::params::accounts,
    $credentials = $swift::params::account_keys,
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
        'python-webob',
    ]:
        ensure => present,
    }

    if $::operatingsystem == 'Ubuntu' {
        package {'python-swauth':
            ensure => present,
        }
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

    file { '/etc/logrotate.d/swift-proxy':
        ensure => present,
        source => 'puppet:///modules/swift/swift-proxy.logrotate.conf',
        mode   => '0444',
    }

    rsyslog::conf { 'swift-proxy':
        source   => 'puppet:///modules/swift/swift-proxy.rsyslog.conf',
        priority => 30,
    }

    file { '/usr/local/lib/python2.7/dist-packages/wmf/':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/swift/SwiftMedia/wmf/',
        recurse => 'remote',
    }
}
