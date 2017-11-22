# == Class superset
#
class superset(
    $port              = 9080,
    $statsd            = undef,
    $workers           = 4,
    $database_uri      = 'sqlite:////tmp/superset.db',
    $secret_key        = '\2\1thisismyscretkey\1\2\e\y\y\h',
    $password_mapping  = undef,
    $deployment_user   = 'analytics_deploy',
    $contact_group     = 'admins',
) {
    requires_os('debian >= jessie')
    require_package('python', 'virtualenv', 'firejail')

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
        gid     => 'superset',
        shell   => '/bin/bash',
        system  => true,
        require => Group['superset'],
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
        group   => 'root',
        mode    => '0444',
        content => template('superset/gunicorn_config.py.erb'),
    }

    file { '/etc/superset/superset_config.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('superset/superset_config.py.erb'),
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
            Scap::Target['analytics/superset/deploy'],
            File['/etc/firejail/superset.profile'],
            File['/etc/superset/gunicorn_config.yaml'],
            File['/etc/superset/superset_config.yaml'],
            User['superset'],
            Systemd::Syslog['superset'],
        ],
    }

    monitoring::service { 'superset':
        description   => 'superset',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
        require       => Systemd::Service['superset'],
    }
}
