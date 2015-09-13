# == Class: sentry
#
# Sentry is a real-time, platform-agnostic error logging and aggregation
# platform.
#
# Installation:
#   1. Apply the role
#   2. (if admin_user is not set) run sudo /srv/deployment/sentry/sentry/bin/sentry --config=<cfg_file> createuser --superuser --email=<email>
# Update:
#   1. Apply the role with the newer version of Sentry
#   2. Run sudo /srv/deployment/sentry/sentry/bin/sentry --config=<cfg_file> upgrade
#
# === Parameters
#
# [*db_user*]
#   MySQL user to use to connect to the database.
#
# [*db_pass*]
#   Password for MySQL account.
#
# [*manage_db*]
#   Whether Puppet should automatically set up a database and create the
#   admin user or leave that as a manual task.
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
    $db_pass,
    $host_name,
    $smtp_host,
    $smtp_user,
    $smtp_pass,
    $sentry_dir,
    $secret_key,
    $admin_email,
    $admin_pass    = undef,
    $db_user       = 'sentry',
    $manage_db     = true,
    $sentry_branch = 'master',
) {
    include ::nginx
    include ::nginx::ssl
    include ::postgresql::server
    include ::redis

    git::clone { 'operations/software/sentry':
        ensure    => latest,
        directory => $sentry_dir,
        branch    => $sentry_branch,
    }


    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
    # The rest of the python packages are packaged as a venv inside sentry/sentry

    require_package('python-beautifulsoup')
    require_package('python-celery')
    require_package('python-cssutils')
    require_package('python-dateutil')
    require_package('python-django-crispy-forms')
    require_package('python-django-jsonfield')
    require_package('python-django-picklefield')
    require_package('python-ipaddr')
    require_package('python-mock')
    require_package('python-progressbar')
    require_package('python-psycopg2')
    require_package('python-pytest')
    require_package('python-redis')
    require_package('python-setproctitle')
    require_package('python-six')

    user { 'sentry':
        ensure => present,
        gid    => 'sentry',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    group { 'sentry':
        ensure => present,
        system => true,
    }

    file { '/etc/sentry.conf.py':
        ensure  => present,
        content => template('sentry/sentry.conf.py.erb'),
        owner   => 'sentry',
        group   => 'sentry',
        mode    => '0640',
    }

    file { '/usr/local/sbin/sentry-auth':
        source  => 'puppet:///modules/sentry/sentry-auth',
        mode    => '0555',
    }

    if $manage_db {
        postgresql::user { $db_user:
            ensure    => present,
            user      => $db_user,
            password  => $db_pass,
            pgversion => '9.4',
            before    => Postgresql::Db['sentry'],
            require   => User['sentry'],
        }

        postgresql::db { 'sentry:'
            ensure     => present,
            name       => 'sentry',
            owner      => $db_user,
        }

        exec { 'initialize_sentry_database':
            command     => "${sentry_dir}/bin/sentry upgrade --noinput",
            user        => 'sentry',
            environment => 'SENTRY_CONF=/etc/sentry/sentry.conf.py',
            unless      => "/usr/bin/pg_dump --schema-only --dbname=sentry --table='sentry_*'",
            require     => [
                Git::Clone['operations/software/sentry'],
                Postgresql::Db['sentry'],
                File['/etc/sentry.conf.py']
            ],
            before      => [
                Base::Service_unit['sentry-worker'],
                Base::Service_unit['sentry']
            ],
        }

        if $admin_pass {
            exec { 'create_sentry_admin':
                command => "/usr/local/sbin/sentry-auth set ${admin_email} ${admin_pass}",
                unless  => "/usr/local/sbin/sentry-auth check ${admin_email} ${admin_pass}",
                subscribe => [
                    Exec['initialize_sentry_database'],
                    File['/usr/local/sbin/sentry-auth'],
                ]
            }
        }
    }

    base::service_unit { 'sentry-worker':
        ensure    => present,
        systemd   => true,
        subscribe => File['/etc/sentry.conf.py'],
    }

    base::service_unit { 'sentry':
        ensure    => present,
        systemd   => true,
        require   => Base::Service_unit['sentry-worker'],
        subscribe => File['/etc/sentry.conf.py'],
    }

    nginx::site { 'sentry':
        content => template('sentry/sentry.nginx.erb'),
    }
}
