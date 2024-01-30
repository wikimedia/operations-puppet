# == Class superset
# Installs superset via scap and runs it.
#
# If you are providing a custom $database_uri, you must ensure that the database exists
# and the configured db user/pass in the URI can write to that database.
# Tables will be auto created.

# An admin user with $admin_user and $admin_password will be created for you in the
# database.  However, if you are using a custom $auth_type, this admin user will not
# be useable.  To set up an admin user for your auth type,, run the
# fabmanager create-user command and add a user with details that match the user's account
# in whatever alternative auth you are using, minus the password. E.g.:
# /srv/deployment/analytics/superset/venv/bin/fabmanager create-admin --app superset --username Ottomata --email otto@wikimedia.org --firstname Andrew --lastname Otto --password BLANK
# This should match exactly the user in your alternative auth (e.g. LDAP),
# except for the password.  The password here does not matter, as the value stored in the
# database will not be used for authentication with your alternative auth type.
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
# [*worker_class*]
#   Gunicorn worker-class.  Default: sync
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
# [*auth_type*]
#   An auth type from flask_appbuilder.security.manager.
#
# [*auth_settings*]
#   Hash of additional auth settings to render in superset_config.py
#
# [*statsd*]
#   statsd host:port
#
# [*deployment_user*]
#   scap deployment user
#
# [*gunicorn_app*]
#   In Superset 0.36.0+ gunicorn needs a different appname for
#   Superset. Default is still for older releases, up to 0.35.x
#   Default: 'superset.app'
#
# [*enable_cas*]
#   Enable authentication via CAS instead of LDAP
#
# [*enable_presto_nested_data*]
#   Enable the PRESTO_NESTED_DATA feature flag, which displays nested columns in the UI
#
# [*metadata_cache_uri*]
#   If specified, Superset uses this to cache its own metadata to speed up rendering the interface.
#
# [*data_cache_uri*]
#   If specified, Superset uses this to cache the results of data queries.
#
# [*filter_state_cache_uri*]
#   If specified, Superset uses this to cache its dashboard filter state.
#
# [*explore_form_data_cache_uri*]
#   If specified, Superset uses this to cache the explorer form data.
#
class superset (
    Stdlib::Port $port                            = 9080,
    String $database_uri                          = 'sqlite:////var/lib/superset/superset.db',
    Integer $workers                              = 1,
    String $worker_class                          = 'sync',
    String $admin_user                            = 'admin',
    String $admin_password                        = 'admin',
    String $secret_key                            = 'not_really_a_secret_key',
    Optional[Hash] $password_mapping              = undef,
    Optional[String] $auth_type                   = undef,
    Optional[Hash] $auth_settings                 = undef,
    Optional[String] $statsd                      = undef,
    String $deployment_user                       = 'analytics_deploy',
    String $gunicorn_app                          = 'superset:app',
    Boolean $enable_cas                           = false,
    Boolean $enable_presto_nested_data            = false,
    Optional[String] $metadata_cache_uri          = undef,
    Optional[String] $data_cache_uri              = undef,
    Optional[String] $filter_state_cache_uri      = undef,
    Optional[String] $explore_form_data_cache_uri = undef,
) {
    ensure_packages([
        'virtualenv',
        'firejail',
    ])

    # Add the required memcached support package if any of the cache backends are specified
    if $metadata_cache_uri or $data_cache_uri or $filter_state_cache_uri or $explore_form_data_cache_uri {
        ensure_packages(['python3-pylibmc'])
    }

    if $worker_class == 'gevent' {
        if debian::codename::ge('bullseye') {
            ensure_packages(['python3-gevent'])
        } else {
            ensure_packages(['python-gevent'])
        }
    }

    $deployment_dir = '/srv/deployment/analytics/superset/deploy'
    $virtualenv_dir = '/srv/deployment/analytics/superset/venv'

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
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/superset/superset.profile.firejail',
    }

    file { '/etc/superset':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $enable_cas {
        $remote_user = 'HTTP_X_CAS_UID'
    } else {
        $remote_user = 'HTTP_X_REMOTE_USER'
    }

    file { '/etc/superset/gunicorn_config.py':
        ensure  => file,
        owner   => 'root',
        group   => 'superset',
        mode    => '0444',
        content => template('superset/gunicorn_config.py.erb'),
    }

    file { '/etc/superset/superset_config.py':
        ensure  => file,
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

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
    profile::auto_restarts::service { 'superset': }

    systemd::service { 'superset':
        ensure  => present,
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
