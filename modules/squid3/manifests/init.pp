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

    if os_version('debian >= stretch') {
        $squid = 'squid'
    } else {
        $squid = 'squid3'
    }
    file { "/etc/${squid}/squid.conf":
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => $config_source,
        content => $config_content,
        require => Package[$squid],
    }

    logrotate::conf { $squid:
        ensure => $ensure,
        source => "puppet:///modules/squid3/${squid}-logrotate",
    }

    package { $squid:
        ensure => $ensure,
    }

    service { $squid:
        ensure    => ensure_service($ensure),
        require   => File["/etc/${squid}/squid.conf"],
        subscribe => File["/etc/${squid}/squid.conf"],
    }
}
