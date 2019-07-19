# == Class profile::analytics::httpd::utils
#
# This class should contain shared puppet code applied to
# all the analytics httpd instances.
#
class profile::analytics::httpd::utils {

    if !defined(File['/var/www']) {
        file { '/var/www':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if !defined(File['/var/www/health_check']) {
        # Allow a simple page to be used as health check.
        # Useful for Nagios monitors.
        file { '/var/www/health_check':
            ensure  => present,
            content => 'OK',
            mode    => '0444',
            require => File['/var/www'],
        }
    }
}