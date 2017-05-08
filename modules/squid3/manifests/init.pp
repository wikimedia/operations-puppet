# Class: squid3
#
# This class installs squid3 and configures it
#
# Parameters:
#
# Actions:
#       Install squid3 and configure it as a caching forward proxy
#
# Requires:
#
# Sample Usage:
#   class { 'squid3': config_source => 'puppet:///modules/foo/squid3-foo.conf' }
#   class { 'squid3': config_content => template('foo/squid3-foo.conf.erb') }


class squid3(
    $ensure  = present,
    $config_content = undef,
    $config_source  = undef,
) {
    validate_re($ensure, '^(present|absent)$')

    file { '/etc/squid3/squid.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => $config_source,
        content => $config_content,
        require => Package['squid3'],
    }

    logrotate::conf { 'squid3':
        ensure  => $ensure,
        source  => 'puppet:///modules/squid3/squid3-logrotate',
    }

    package { 'squid3':
        ensure => $ensure,
    }

    service { 'squid3':
        ensure    => ensure_service($ensure),
        require   => File['/etc/squid3/squid.conf'],
        subscribe => File['/etc/squid3/squid.conf'],
    }
}
