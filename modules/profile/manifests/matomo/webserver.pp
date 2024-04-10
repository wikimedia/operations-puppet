# SPDX-License-Identifier: Apache-2.0
# == Class: profile::matomo::webserver
#
# Apache webserver instance configured with mpm-prefork and mod_php.
# This configuration should be improved with something more up to date like
# mpm-event and php-fpm/hhmv.
#
class profile::matomo::webserver {
    include profile::prometheus::apache_exporter

    $php_version = wmflib::debian_php_version()
    $php_module = "php${php_version}"
    $php_ini = "/etc/php/${php_version}/apache2/php.ini"

    package { "${php_module}-mbstring":
        ensure => 'present',
    }
    package { "${php_module}-xml":
        ensure => 'present',
    }

    package { "libapache2-mod-${php_module}":
        ensure => 'present',
    }

    class { 'httpd':
        modules => ['headers', $php_module, 'rewrite'],
        require => Package["libapache2-mod-${php_module}"],
    }

    class { 'httpd::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/profile/matomo/mpm_prefork.conf',
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    require profile::analytics::httpd::utils
    include profile::idp::client::httpd

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => $php_ini,
        notify => Class['httpd'],
    }

    file_line { 'php_memory_limit':
        line   => 'memory_limit = 256M',
        match  => '^;?memory_limit\s*\=',
        path   => $php_ini,
        notify => Class['httpd'],
    }
}
