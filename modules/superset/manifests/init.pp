# == Class superset
# Installs superset via scap and runs it.
#
# If you are providing a custom $database_uri, you must ensure that the database exists
# and the configured db user/pass in the URI can write to that database.
# Tables will be auto created.
#
# == Parameters
#
# [*port*]
#   Port on which superset will listen for HTTP connections.
#
# [*database_uri*]
#   SQL Alchemy database URI.
#
# [*workers*]
#   Number of gevent workers
#
# [*admin_user*]
#   Web UI admin user
#
# [*admin_password*]
#   Web UI admin user password
#
# [*secret_key*]
#   flask secret key
#
# [*password_mapping*]
#   Hash of sqlalchemy URIs to passwords.  This will be used
#   for the SQLALCHEMY_CUSTOM_PASSWORD_STORE, to allow for
#   passwords to external databases to be provided via configuration,
#   rather than the web UI.
#
# [*statsd*]
#   statsd host:port
#
# [*deployment_user*]
#   scap deployment user
#
class superset(
    $port              = 9080,
    $database_uri      = 'sqlite:////var/lib/superset/superset.db',
    $workers           = 4,
    $admin_user        = 'admin',
    $admin_password    = 'admin',
    $secret_key        = 'not_really_a_secret_key',
    $password_mapping  = undef,
    $statsd            = undef,
    $deployment_user   = 'analytics_deploy',
) {
    requires_os('debian >= jessie')
    require_package('python', 'virtualenv', 'firejail')

    $deployment_dir = '/srv/deployment/analytics/superset/deploy'
    $virtualenv_dir = '/srv/deployment/analytics/superset/venv'

    # superset runs gunicorn with gevent, use debian provided python-gevent.
    require_package('python-gevent')

    scap::target { 'analytics/superset/deploy':
        deploy_user  => $deployment_user,
        service_name => 'superset',
    }

    group { 'superset':
        ensure => present,
        system => true,
    }

    user { 'superset':
        gid        => 'superset',
        shell      => '/bin/bash',
        system     => true,
        managehome => true,
        home       => '/var/lib/superset',
        require    => Group['superset'],
    }

    file { '/etc/firejail/superset.profile':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/superset/superset.profile.firejail',
    }

    file { '/etc/superset':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/superset/gunicorn_config.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'superset',
        mode    => '0444',
        content => template('superset/gunicorn_config.py.erb'),
    }

    file { '/etc/superset/superset_config.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'superset',
        mode    => '0440',
        content => template('superset/superset_config.py.erb'),
    }

    # This will create tables in the superset database and add the web GUI admin user.
    exec { 'init_superset':
        command     => "${deployment_dir}/init_superset.sh ${admin_user} ${admin_password}",
        # Don't run init_superset.sh if superset database exists.
        unless      => "${virtualenv_dir}/bin/python ${deployment_dir}/superset_database_exists.py ${database_uri}",
        user        => 'superset',
        # Set PYTHONPATH to read superset_config.py
        environment => ['PYTHONPATH=/etc/superset', 'SUPERSET_HOME=/var/lib/superset'],
        require     => [
            Scap::Target['analytics/superset/deploy'],
            File['/etc/superset/superset_config.py'],
        ],
    }

    systemd::syslog { 'superset':
        readable_by => 'all',
        base_dir    => '/var/log',
        group       => 'root',
    }

    systemd::service { 'superset':
        ensure  => 'present',
        content => systemd_template('superset'),
        restart => true,
        require => [
            File['/etc/firejail/superset.profile'],
            File['/etc/superset/gunicorn_config.py'],
            Exec['init_superset'],
            Systemd::Syslog['superset'],
        ],
    }
}
