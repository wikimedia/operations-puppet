# == Class: sentry
#
# Sentry is a real-time, platform-agnostic error logging and aggregation
# platform.
#
# === Parameters
#
# [*db_pass*]
#   Password for MySQL account.
#
# [*server_name*]
#   Domain name under which Sentry will be available.
#
# [*git_branch*]
#   Which branch to check out.
#
# [*secret_key*]
#   The secret key required by Sentry.
#
# [*admin_email*]
#   Email address of the application administrator.
#
# [*admin_pass*]
#   Password of the Sentry superuser.
#
class sentry (
    $db_pass,
    $server_name,
    $secret_key,
    $admin_pass,
    $admin_email = 'noc@wikimedia.org',
    $git_branch  = 'master',
) {
    include ::nginx
    include ::nginx::ssl
    include ::postgresql::server
    include ::redis

    require sentry::packages

    git::clone { 'operations/software/sentry':
        ensure    => latest,
        directory => '/srv/sentry',
        branch    => $git_branch,
    }

    group { 'sentry':
        system => true,
    }

    user { 'sentry':
        gid    => 'sentry',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    file { '/etc/sentry.conf.py':
        content => template('sentry/sentry.conf.py.erb'),
        owner   => 'sentry',
        group   => 'sentry',
        mode    => '0640',
        require => Git::Clone['operations/software/sentry'],
    }

    file { '/etc/sentry.d':
        ensure => directory,
        owner  => 'sentry',
        group  => 'sentry',
        mode   => '0750',
    }

    file { '/usr/local/sbin/sentry-auth':
        source  => 'puppet:///modules/sentry/sentry-auth',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/sentry.conf.py'],
    }

    postgresql::user { 'sentry':
        user      => 'sentry',
        password  => $db_pass,
        pgversion => '9.4',
        require   => File['/etc/sentry.conf.py'],
    }

    postgresql::db { 'sentry':
        name    => 'sentry',
        owner   => 'sentry',
        require => Postgresql::User['sentry'],
    }

    exec { 'initialize_sentry_database':
        command     => '/srv/sentry/bin/sentry upgrade --noinput',
        unless      => '/usr/bin/pg_dump --schema-only --dbname=sentry --table=sentry_*',
        environment => 'SENTRY_CONF=/etc/sentry.conf.py',
        user        => 'sentry',
        require     => Postgresql::Db['sentry'],
    }

    exec { 'create_sentry_admin':
        command => "/usr/local/sbin/sentry-auth set ${admin_email} ${admin_pass}",
        unless  => "/usr/local/sbin/sentry-auth check ${admin_email} ${admin_pass}",
        user    => 'sentry',
        require => Exec['initialize_sentry_database'],
    }

    base::service_unit { 'sentry-worker':
        systemd   => true,
        subscribe => File['/etc/sentry.conf.py'],
        require   => Exec['initialize_sentry_database'],
    }

    base::service_unit { 'sentry':
        systemd   => true,
        subscribe => File['/etc/sentry.conf.py'],
        require   => Base::Service_unit['sentry-worker'],
    }

    nginx::site { 'sentry':
        content => template('sentry/sentry.nginx.erb'),
    }
}
