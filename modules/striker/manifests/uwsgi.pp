# = Class: striker::uwsgi
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
# == Parameters:
# [*port*]
#   Port that uWSGI demon should listen on
# [*config*]
#   Configuration for the deployed Django application. Value should be
#   a multi-dimentional hash of values.
# [*deploy_dir*]
#   Directory that Striker will be deployed to via scap3.
#   Default /srv/deployment/striker/deploy.
# [*venv_dir*]
#   Directory to create/manage Python virtualenv in.
#   Default /srv/deployment/striker/venv.
# [*secret_config*]
#   Additional configuration for the deployed Django application. Value should
#   be a multi-dimentional hash of values. Useful for setting configuration
#   values that for one reason or another cannot be provided via `config`
#   (probably because the values need to be kept out of public hiera files).
#   Default {}.
#
class striker::uwsgi(
    $port,
    $config,
    $deploy_dir    = '/srv/deployment/striker/deploy',
    $venv_dir      = '/srv/deployment/striker/venv',
    $secret_config = {},
){
    requires_os('Debian >= jessie')

    # Packages needed by python wheels
    require_package(
        'libffi6',
        'libldap-2.4-2',
        'libmysqlclient18',
        'libsasl2-2',
        'libssl1.0.0',
        'python3',
        'python3-wheel',
        'virtualenv',
    )

    # Generate Striker ini file
    file { '/etc/striker':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/striker/striker.ini':
        ensure  => 'present',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => ini($config, $secret_config),
    }

    service::uwsgi { 'striker':
        port            => $port,
        config          => {
            'chdir'     => "${deploy_dir}/striker",
            'wsgi-file' => 'striker/wsgi.py',
            'plugins'   => 'python3',
            'venv'      => $venv_dir,
        },
        healthcheck_url => '/',
        repo            => 'striker/deploy',
        sudo_rules      => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker status',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker stop',
        ],
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
