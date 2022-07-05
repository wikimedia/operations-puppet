# SPDX-License-Identifier: Apache-2.0
class swift::proxy (
    $proxy_service_host,
    $shard_container_list,
    Hash[String, Hash] $accounts,
    Hash[String, String] $credentials,
    $memcached_servers         = ['localhost'],
    $memcached_port            = 11211,
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
    $enable_wmf_filters        = true,
    $read_affinity             = undef,
) {
    package {[
        'swift-proxy',
    ]:
        ensure => present,
    }

    # eventlet + getaddrinfo is busted in Bullseye, thus use addresses
    # https://phabricator.wikimedia.org/T283714
    $memcached_addresses = $memcached_servers.map |$server| {
        $addr = ipresolve($server, 4); "${addr}:${memcached_port}"
    }

    $base_middlewares = $enable_wmf_filters ? {
        true  => ['ensure_max_age', 'rewrite', 'healthcheck', 'cache', 'container_sync', 'tempurl',
                  'ratelimit', 'tempauth', 'cors', 'proxy-logging', 'proxy-server'],
        false => ['healthcheck', 'cache', 'container_sync', 'bulk', 'tempurl', 'ratelimit', 's3api',
                  'tempauth', 'slo', 'proxy-logging', 'proxy-server'],
    }

    $middlewares = debian::codename::ge('bullseye') ? {
        # proxy-logging is repeated in the pipeline on purpose
        # https://bugs.launchpad.net/swift/+bug/1939888
        true  => ['proxy-logging', 'listing_formats'] + $base_middlewares,
        false => $base_middlewares,
    }

    file { '/etc/swift/proxy-server.conf':
        owner     => 'swift',
        group     => 'swift',
        mode      => '0440',
        content   => template('swift/proxy-server.conf.erb'),
        require   => Package['swift-proxy'],
        show_diff => false,
    }

    if $dispersion_account != undef {
        file { '/etc/swift/dispersion.conf':
            owner     => 'swift',
            group     => 'swift',
            mode      => '0440',
            content   => template('swift/dispersion.conf.erb'),
            require   => Package['swift'],
            show_diff => false,
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

    if debian::codename::lt('bullseye') {
        $python_version = '2.7'
        $monotonic_package = 'python-monotonic'
    } else {
        $python_version = '3.9'
        $monotonic_package = 'python3-monotonic'
    }

    ensure_packages($monotonic_package)

    file { "/usr/local/lib/python${python_version}/dist-packages/wmf/":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/swift/python${python_version}/SwiftMedia/wmf/",
        recurse => 'remote',
    }
}
