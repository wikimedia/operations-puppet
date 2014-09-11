# Class: url_downloader
#
# This class installs squid as a forward proxy for fetching URLs
#
# Parameters:
#   $service_ip
#       The IP on which the proxy listens on and uses to fetch URLs
#
# Actions:
#       Install squid and configure it as a forward fetching proxy
#
# Requires:
#
# Sample Usage:
#       class { '::url_downloader':
#           service_ip  => '10.10.10.10' # Probably a public ip though
#       }
class url_downloader($service_ip) {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $package_name = 'squid3'
    } else {
        $package_name = 'squid'
    }

    $confdir = "/etc/${package_name}"
    $service_name = $package_name

    file { "${confdir}/squid.conf":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("url-downloader/${package_name}.conf.erb"),
    }

    file { "/etc/logrotate.d/${package_name}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/url-downloader/${package_name}-logrotate",
    }

    package { $package_name:
        ensure => installed,
    }

    service { $service_name:
        ensure => running,
    }

    Package[$package_name] -> Service[$service_name]
    Package[$package_name] -> File["/etc/logrotate.d/${package_name}"]
    Package[$package_name] -> File["${confdir}/squid.conf"]
    File["${confdir}/squid.conf"] ~> Service[$service_name] # also notify
}
