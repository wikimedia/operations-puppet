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
#   $managed_puppet_models
#       Boolean. Defaults to false. Set this if you use this module in a
#       development environment in order to have the module create the puppet
#       tables for you. Do not use in production.
#   $port
#       Gunicorn's listening port
#   $admins
#       ('admin team', 'adminteam@example.com')
#   $debug
#       Boolean. The Django DEBUG setting
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
    $managed_puppet_models=false,
    $port=8090,
    $admins=undef,
    $debug=false,
    $ensure='present',
) {

    $packages = [
        'python-django',
        'python-django-south',
        'python-whoosh',
        'python-ipy',
        'gunicorn',
        'python-ldap',
        'python-mysqldb',
    ]
    require_package($packages)

    # Note: we re-use the librenms deploy user as both servermon and librenms
    # are tools deployed by ops solely currently and adding a user just for
    # servermon makes no sense. At some point, if this patterns is done for
    # multiple softwares we could rename the user to better reflect that
    scap::target { 'servermon/servermon':
        deploy_user => 'deploy-librenms',
    }

    service { 'gunicorn':
        ensure    => ensure_service($ensure),
        enable    => true,
        hasstatus => false,
    }

    file { "${directory}/servermon/settings.py":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/settings.py.erb'),
    }

    file { '/etc/gunicorn.d/servermon':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('servermon/gunicorn.erb'),
        require => Package['gunicorn'],
    }

    cron { 'servermon_make_updates':
        command => "${directory}/manage.py make_updates",
        user    => 'www-data',
        hour    => '*',
        minute  => '35',
    }
}
