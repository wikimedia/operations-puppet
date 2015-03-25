# == Class: sentry
#
# Sentry is a realtime, platform-agnostic error logging and aggregation platform.
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
    $smtp_host,
    $smtp_user,
    $smtp_pass,
    $admin_email,
    $cfg_file,
    $secret_key,
    $admin_user,
    $admin_pass,
) {
    package { 'sentry/sentry':
        provider => 'trebuchet',
    }

    $deploy_dir = '/srv/deployment/sentry/sentry'
    $sentry_cli = "${deploy_dir}/bin/sentry --config='${cfg_file}'"

    require_package('postgresql')

    # System packages compatible with Sentry 7.4.3 on Debian Jessie on 2015-03-31
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
        pgversion  => '9.4',
        require    => Postgresql::User[$db_user],
    }

    file { $cfg_file:
        ensure  => present,
        group   => $group,
        content => template('sentry/sentry.conf.py.erb'),
        mode    => 0640,
    }

    exec { 'initialize sentry database':
        command => "${sentry_cli} upgrade",
        user    => $user,
        require => [Package['sentry/sentry'], Postgresql::Db[$db_name], File[$cfg_file]],
    }

    file { '/etc/systemd/system/sentry.service':
        ensure  => present,
        content => template('sentry/sentry.service.erb'),
        mode    => '0444',
    }

    service { 'sentry':
        ensure     => running,
        provider   => 'systemd',
        require    => [Package['sentry/sentry'], Postgresql::Db[$db_name]],
        subscribe  => File[$cfg_file],
    }
}

