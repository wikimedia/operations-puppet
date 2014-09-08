# Class: servermon
#
# This class installs and configures software needed for running servermon
#
# Parameters:
#   $directory
#       Where the code is (already) placed at
#   $secret_key
#       Django's session secret key
#   $db_name
#       Filename if sqlite3, actual DB name otherwise
#   $db_engine
#       mysql, sqlite3, postgres
#   $db_user
#       The database user, empty if sqlite3
#   $db_password
#       The database user's password, empty if sqlite3
#   $db_host
#       The database host, empty if sqlite3
#   $db_port
#       The database port, empty if sqlite3
#   $port
#       Gunicorn's listening port
#   $admins
#       ('admin team', 'adminteam@example.com')
#
# Actions:
#       Install/configure gunicorn
#       Configure servermon
#
# Requires:
#
# Sample Usage:
#   class { '::servermon':
#       ensure     => 'present',
#       directory  => '/srv/servermon/servermon',
#       secret_key => 'supersecretkey',
#       db_name    => 'testdb',
#       admins     => '( "Your admins", "admin@example.com")',
#   }
#
class servermon(
    $directory,
    $secret_key,
    $db_name,
    $db_engine='sqlite3',
    $db_user='',
    $db_password='',
    $db_host='',
    $db_port='',
    $port=8090,
    $admins=undef,
    $ensure='present',
) {

    package { [
        'python-django',
        'python-django-south',
        'python-whoosh',
        'python-ldap',
        'python-ipy',
        'gunicorn',
    ]:
        ensure => $ensure,
    }

    $service_ensure = $ensure ? {
        present => 'running',
        absent  => 'stopped',
        default => 'running',
    }

    service { 'gunicorn':
        ensure => $service_ensure,
    }

    file { "$directory/settings.py":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/settings.py.erb'),
    }

    file { "$directory/urls.py":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/servermon/urls.py',
    }

    file { '/etc/gunicorn.d/servermon':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/gunicorn.erb'),
        require => Package['gunicorn'],
    }
}
