# Class: apache
#
# This class installs Apache
#
# Parameters:
#
# Actions:
#   - Install Apache
#   - Manage Apache service
#
# Requires:
#
# Sample Usage:
#
class apache ( $service_enable = true ) {
    validate_bool($service_enable)

    package { 'httpd':
        name   => 'apache2',
        ensure => installed,
    }

    service { 'httpd':
        name      => 'apache2',
        ensure    => $service_enable,
        enable    => $service_enable,
        subscribe => Package['httpd'],
    }

    file { 'http_vdir':
        path    => '/etc/apache2/sites-enabled/',
        ensure  => directory,
        recurse => true,
        purge   => true,
        notify  => Service['httpd'],
        require => Package['httpd'],
    }
}
