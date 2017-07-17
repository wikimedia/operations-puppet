# == Class: profile::piwik::database
#
# Set up a simple mysql database for Piwik. This config is not standard
# (as in following Wikimedia's puppet classes) because of historic reasons,
# but it will refactored in the future. For the moment it contains the very
# basic configs added to the standard Debian mysql deployment.
#
class profile::piwik::database {

    require_package('mysql-server')

    file { '/etc/mysql/my.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/profile/piwik/my.cnf',
        require => Package['mysql-server'],
    }

}