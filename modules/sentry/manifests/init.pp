# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
#
# Installation:
#   1. apply the role
#   2. (if admin_user is not set) run sudo /srv/deployment/sentry/sentry/bin/sentry --config=<cfg_file> createuser --superuser --email=<email>
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
#   MySQL user to use to connect to the database.
#
# [*db_pass*]
#   Password for MySQL account.
#
# [*db_name*]
#   Logical MySQL database name.
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
# [*sentry_branch*]
#   Which branch to check out.
#
# [*sentry_dir*]
#   The directory where Sentry and its dependencies should be installed.
#
# [*cfg_file*]
#   Sentry configuration file. Needs to end in '.py'. The file will be created by puppet.
#
# [*secret_key*]
#   The secret key required by Sentry.
#
# [*admin_email*]
#   Email address of the application administrator. Also doubles as superuser login if
#   $admin_pass is set.
#
# [*admin_pass*]
#   Password of the Sentry superuser. Optional, superuser will not be created if not set.
#
class sentry (
    $user = 'sentry',
    $group = 'sentry',
    $db_user = 'sentry',
    $db_pass,
    $db_name = 'sentry',
    $host_name,
    $smtp_host,
    $smtp_user,
    $smtp_pass,
    $sentry_branch = 'master',
    $sentry_dir,
    $cfg_file = '/etc/sentry.conf.py',
    $secret_key,
    $admin_email,
    $admin_pass = undef,
) {
    if $cfg_file !~ /.py$/ {
        fail('sentry::cfg_file must have .py extension')
    }

    git::clone{ 'operations/software/sentry':
        ensure    => latest,
        directory => $sentry_dir,
        branch    => $sentry_branch,
    }

    $sentry_cli = "${sentry_dir}/bin/sentry --config='${cfg_file}'"

    include postgresql::server
    include nginx
    include nginx::ssl
    include redis

    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
    # The rest of the python packages are packaged as a venv inside sentry/sentry

    require_package('python-beautifulsoup')
    require_package('python-celery')
    require_package('python-cssutils')
    require_package('python-django-crispy-forms')
    require_package('python-django-jsonfield')
    require_package('python-django-picklefield')
    require_package('python-ipaddr')
    require_package('python-mock')
    require_package('python-progressbar')
    require_package('python-psycopg2')
    require_package('python-pytest')
    require_package('python-dateutil')
    require_package('python-redis')
    require_package('python-six')
    require_package('python-setproctitle')

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

    $table_exists = "/usr/bin/psql '${db_name}' --tuples-only --command 'SELECT table_name FROM information_schema.tables;' | /bin/grep -q '^ sentry_'"
    exec { 'initialize sentry database':
        command => "${sentry_cli} upgrade --noinput",
        user    => $user,
        unless  => $table_exists,
        require => [Git::Clone['operations/software/sentry'], Postgresql::Db[$db_name], File[$cfg_file]],
    }

    if $admin_pass {
        exec { 'create sentry superuser':
            command     => "${sentry_cli} createuser --no-input --superuser --email ${admin_email} --password ${admin_pass}",
            user        => $user,
            refreshonly => true,
            subscribe   => Exec['initialize sentry database'],
        }
    }

    base::service_unit { 'sentry-worker':
        ensure    => present,
        systemd   => true,
        require   => Exec['initialize sentry database'],
        subscribe => File[$cfg_file],
    }

    base::service_unit { 'sentry':
        ensure    => present,
        systemd   => true,
        require   => [Exec['initialize sentry database'], Base::Service_unit['sentry-worker']],
        subscribe => File[$cfg_file],
    }

    nginx::site { 'sentry':
        content => template('sentry/sentry.nginx.erb'),
    }
}

