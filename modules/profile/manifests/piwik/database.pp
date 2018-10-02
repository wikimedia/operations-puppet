# == Class: profile::piwik::database
#
# Set up a simple mysql database for Piwik. This config is not standard
# (as in following Wikimedia's puppet classes) because of historic reasons,
# but it will refactored in the future. For the moment it contains the very
# basic configs added to the standard Debian mysql deployment.
#
class profile::piwik::database {

    # This is a hacky temporary measure
    # to allow to configure a proper mariadb instance
    # on the new Matomo/Piwik host keeping the other
    # unchanged.
    # Bug: T202962
    if os_version('debian == jessie') {
        require_package('mysql-server')

        file { '/etc/mysql/my.cnf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/profile/piwik/my.cnf',
            require => Package['mysql-server'],
        }
    } else {

        package { 'mysql-server':
            ensure => absent,
        }

        $mariadb_socket = '/run/mysqld/mysqld.sock'

        class { '::mariadb::packages_wmf': }

        class { '::mariadb::config':
            config    => 'profile/piwik/my.cnf.erb',
            socket    => $mariadb_socket,
            port      => 3306,
            datadir   => '/var/lib/mysql',
            basedir   => '/opt/wmf-mariadb101',
            read_only => false,
            require   => Class['mariadb::packages_wmf'],
        }

        class { '::mariadb::service':
            ensure  => 'running',
            manage  => true,
            enable  => true,
            require => Class['mariadb::config'],
        }

        profile::prometheus::mysqld_exporter_instance {'matomo':
            socket => $mariadb_socket,
        }
    }
}