# == Class: apache
#
# Provisions Apache web server package and service.
#
# It accomodates different use-cases by expecting the caller to pass in
# full configuration files, rather than generating configuration files
# based on complex parameters and switches.
#
# The module provides backwards-compatibility with Apache 2.2 by enabling
# mod_filter and mod_access_compat by default.
#
class apache {
    include ::apache::mod::access_compat  # enables allow/deny syntax in 2.4
    include ::apache::mod::filter         # enables AddOutputFilterByType in 2.4
    include ::apache::monitoring          # send metrics to Diamond
    include ::apache::mpm                 # prefork by default

    $conf_types     = ['conf', 'env', 'sites']
    $available_dirs = apply_format('/etc/apache2/%s-available', $conf_types)
    $enabled_dirs   = apply_format('/etc/apache2/%s-enabled', $conf_types)

    package { 'apache2':
        ensure => present,
    }

    service { 'apache2':
        ensure     => running,
        enable     => true,
        provider   => 'debian',
        hasrestart => true,
        restart    => '/usr/sbin/service apache2 reload',
        require    => Package['apache2'],
    }

    exec { 'apache2_test_config_and_restart':
        command     => '/usr/sbin/apache2ctl configtest',
        notify      => Exec['apache2_hard_restart'],
        before      => Service['apache2'],
        refreshonly => true,
    }

    exec { 'apache2_hard_restart':
        command     => '/usr/sbin/service apache2 restart',
        refreshonly => true,
        before      => Service['apache2'],
    }

    file { $available_dirs:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['apache2'],
    }

    file { $enabled_dirs:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    file_line { 'load_env_enabled':
        line    => 'for f in /etc/apache2/env-enabled/*.sh; do [ -r "$f" ] && . "$f" >&2; done || true',
        match   => 'env-enabled',
        path    => '/etc/apache2/envvars',
        require => Package['apache2'],
    }

    apache::conf { 'defaults':
        source   => 'puppet:///modules/apache/defaults.conf',
        priority => 0,
    }

    apache::site { 'dummy':
        source   => 'puppet:///modules/apache/dummy.conf',
        priority => 0,
    }

    # manage logrotate periodicity and keeping period
    #
    # The augeas rule in apache::logrotate needs /etc/logrotate.d/apache2 which
    # is provided by apache2 package
    class {'::apache::logrotate':
        require => Package['apache2'],
    }
}
