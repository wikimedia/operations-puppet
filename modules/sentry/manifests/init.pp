# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
#
# Installation:
#   1. apply the role
#   2. run sudo /srv/deployment/sentry/sentry/bin/sentry --config=<cfg_file> createuser --superuser --email=<email>
# Update:
#   1. apply the role with the newer version of Sentry
#   2. run sudo /srv/deployment/sentry/sentry/bin/sentry --config=<cfg_file> upgrade
#
# === Parameters
# [*user*]
#   System user that runs Sentry.
#
# [*group*]
#   Group of the system user.
#
# [*db_user*]
#   MySQL user to use to connect to the database (example: 'wikidb').
#
# [*db_pass*]
#   Password for MySQL account (example: 'secret123').
#
# [*db_name*]
#   Logical MySQL database name (example: 'sentry').
#
# [*host_name*]
#   Domain name under which Sentry will be available.
#
# [*smtp_host*]
#   SMTP server host name; used to send email alerts on new errors.
#
# [*smtp_user*]
#   SMTP username.
#
# [*smtp_pass*]
#   SMTP password.
#
# [*admin_email*]
#   Email address of the application administrator.
#
# [*cfg_file*]
#   Sentry configuration file. Needs to end in '.py'. (example: '/etc/sentry.conf.py')
#   The file will be generated by puppet.
#
# [*secret_key*]
#   The secret key required by Sentry.
#
# [*admin_user*]
#   Username of the Sentry superuser. (example: 'admin')
#
# [*admin_pass*]
#   Password of the Sentry superuser. (example: 'vagrant')
#
class sentry (
    $user,
    $group,
    $db_user,
    $db_pass,
    $db_name,
    $host_name,
    $smtp_host,
    $smtp_user,
    $smtp_pass,
    $admin_email,
    $cfg_file,
    $secret_key,
    $admin_user, #TODO actually use these
    $admin_pass,
) {
    if $cfg_file !~ /.py$/ {
        fail('sentry::cfg_file must have .py extension')
    }

    package { 'sentry/sentry':
        provider => 'trebuchet',
    }

    $deploy_dir = '/srv/deployment/sentry/sentry'
    # weird quoting courtesy of https://github.com/systemd/systemd/issues/624
    $sentry_cli = "${deploy_dir}/bin/sentry '--config=${cfg_file}'"

    include postgresql::server
    include nginx
    include nginx::ssl

    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
    # The rest of the python packages are packaged as a venv inside sentry/sentry
    require_package('python-beautifulsoup')
    require_package('python-cssutils')
    require_package('python-django-crispy-forms')
    require_package('python-django-jsonfield')
    require_package('python-django-picklefield')
    require_package('python-ipaddr')
    require_package('python-mock')
    require_package('python-progressbar')
    require_package('python-pytest')
    require_package('python-redis')
    require_package('python-six')
    require_package('python-setproctitle')
    require_package('python-psycopg2')

    user { $user:
        ensure => present,
        gid     => $group,
        shell   => '/bin/false',
        home    => '/nonexistent',
        system  => true,
    }

    group { $group:
        ensure => present,
        system => true,
    }

    postgresql::user { $db_user:
        ensure     => present,
        user       => $db_user,
        password   => $db_pass,
        pgversion  => '9.4',
    }

    postgresql::db { $db_name:
        ensure     => present,
        name       => $db_name,
        owner      => $db_user,
        require    => Postgresql::User[$db_user],
    }

    file { $cfg_file:
        ensure  => present,
        group   => $group,
        content => template('sentry/sentry.conf.py.erb'),
        mode    => 0640,
    }

    $table_exists = "/usr/bin/psql '{$db_name}' --tuples-only --command 'SELECT table_name FROM information_schema.tables;' | /bin/grep -q '^ ${sentry}'"
    exec { 'initialize sentry database':
        command => "${sentry_cli} upgrade",
        user    => $user,
        unless  => $table_exists,
        require => [Package['sentry/sentry'], Postgresql::Db[$db_name], File[$cfg_file]],
    }

    base::service_unit { 'sentry':
        ensure   => present,
        systemd  => true,
        require  => [Package['sentry/sentry'], File[$cfg_file], Postgresql::Db[$db_name]],
    }

    nginx::site { 'sentry':
        content => template('sentry/sentry.nginx.erb'),
    }
}

