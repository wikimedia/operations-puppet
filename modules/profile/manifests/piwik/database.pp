# == Class: profile::piwik::database
#
# Set up a simple mysql database for Piwik. This config is not standard
# (as in following Wikimedia's puppet classes) because of historic reasons,
# but it will refactored in the future. For the moment it contains the very
# basic configs added to the standard Debian mysql deployment.
#
class profile::piwik::database(
    $database_port           = lookup('profile::piwik::database', { 'default_value' => 3306 }),
    $backup_hosts_ferm_range = lookup('profile::piwik::database::backup_hosts_ferm_range', { 'default_value' => undef }),
) {

    package { 'mysql-server':
        ensure => absent,
    }

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    class { '::mariadb::packages_wmf': }

    class { '::mariadb::config':
        config    => 'profile/piwik/my.cnf.erb',
        socket    => $mariadb_socket,
        port      => $database_port ,
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

    if $backup_hosts_ferm_range {
        ferm::service { 'mariadb':
            proto  => 'tcp',
            port   => $database_port,
            srange => $backup_hosts_ferm_range,
        }
    }

    profile::prometheus::mysqld_exporter_instance {'matomo':
        socket => $mariadb_socket,
    }
}