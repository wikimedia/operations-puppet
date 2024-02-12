# SPDX-License-Identifier: Apache-2.0
# == Class: ncmonitor
# Deployment of ncmonitor configuration, services, and executable
#
# === Parameters
# [*ensure*]
#   If 'present', the module will be configured with all users,
#   files, and services enabled. If 'absent', all of these are
#   removed/disabled.
#
#   Default: 'present'
#
# [*nameservers*]
#   An array of domain names to use as nameservers.
#
#   Default: undef
#
# [*markmon_api_user*]
#   MarkMonitor API username
#
#   Default: undef
#
# [*markmon_api_pass*]
#   MarkMonitor API password
#
#   Default: undef
#
# [*http_proxy*]
#   Endpoint to proxy ncmonitor's systemd unit traffic (via
#   Environment=).
#
#   Default: undef

class ncmonitor(
    Wmflib::Ensure            $ensure,
    Array[Stdlib::Host]       $nameservers,
    String                    $markmon_api_user,
    String                    $markmon_api_pass,
    Optional[Stdlib::HTTPUrl] $http_proxy,
) {
    $config = {
        nameservers => $nameservers,
        markmonitor => {
            username => $markmon_api_user,
            password => $markmon_api_pass,
        },
    }

    package { 'ncmonitor':
        ensure  => $ensure,
        require => Exec['apt-get update'],
    }

    systemd::sysuser { 'ncmonitor':
        ensure   => $ensure,
        shell    => '/bin/sh',
        home_dir => '/nonexistent',
    }

    $ensure_conf_dir = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }

    file { '/etc/ncmonitor/':
        ensure => $ensure_conf_dir,
        owner  => 'ncmonitor',
        group  => 'root',
        mode   => '0700',
    }

    file { '/etc/ncmonitor/ncmonitor.yaml':
        ensure    => $ensure,
        owner     => 'ncmonitor',
        group     => 'root',
        mode      => '0400',
        content   => to_yaml($config),
        require   => Package['ncmonitor'],
        backup    => false,
        show_diff => false,
    }

    # Some environments (e.g. WMCS) should not have proxies set. Merely setting
    # a default value for the 'environment' attribute would cause empty
    # Environment= entries to be created. We need to either specify
    # 'environment' with values or not at all.
    $timer_defaults = {
        ensure      => $ensure,
        user        => 'ncmonitor',
        description => 'Verify/Sync non-canonical domains with downstream services',
        command     => '/usr/bin/ncmonitor',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'daily',
        },
        require     => Package['ncmonitor'],
    }

    $timer = $http_proxy? {
        Stdlib::HTTPUrl => {
            'ncmonitor' => {
                environment => {
                    'HTTP_PROXY'  => $http_proxy,
                    'HTTPS_PROXY' => $http_proxy,
                }
            }
        },
        default         => {'ncmonitor' => {}},
    }

    create_resources(systemd::timer::job, $timer, $timer_defaults)

}
