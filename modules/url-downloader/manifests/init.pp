class url-downloader {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $confdir = '/etc/squid3'
        $package_name = 'squid3'
        $service_name = 'squid3'
    } else {
        $confdir = '/etc/squid'
        $package_name = 'squid'
        $service_name = 'squid'
    }

    file { "${confdir}/squid.conf":
        require => Package[$package_name],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        #TODO: inspect this
        source  => "puppet:///modules/url-downloader/{$package_name}.conf",
    }

    file { "/etc/logrotate.d/${package_name}":
        ensure  => present,
        require => Package[$package_name],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/url-downloader/${package_name}-logrotate",
    }

    package { $package_name:
        ensure => installed,
    }

    service { $service_name:
        ensure    => running,
        require   => [
                      File["${confdir}/squid.conf"],
                      Package[$package_name],
                     ],
        subscribe => File["${confdir}/squid.conf"],
    }
}
