# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::prometheus_manager (
    String $db_hostname       = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_hostname', {default_value => 'wu5emp5wblz.svc.trove.eqiad1.wikimedia.cloud'}),
    String $db_database       = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_database', {default_value => 'prometheusconfig'}),
    String $db_user_username  = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_user_username', {default_value => 'configuser'}),
    String $db_user_password  = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_user_password'),
    String $db_admin_username = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_admin_username', {default_value => 'configadmin'}),
    String $db_admin_password = lookup('profile::wmcs::metricsinfra::prometheus_manager::db_admin_password'),
) {
    $gitdir = '/var/lib/git'
    $clone_dir = "${gitdir}/cloud/metricsinfra/prometheus-manager"
    $venv_dir = "${clone_dir}/venv"
    $config_dir = '/etc/prometheus-manager'
    $config_file = "${config_dir}/config.yaml"
    $metrics_dir = '/run/prometheus-manager-metrics'

    wmflib::dir::mkdir_p("${gitdir}/cloud/metricsinfra")

    file { $config_dir:
        ensure => directory,
    }

    $config = {
        'DATABASE' => {
            'HOST'     => $db_hostname,
            'DATABASE' => $db_database,
            'USER'     => {
                'USERNAME' => $db_user_username,
                'PASSWORD' => $db_user_password,
            },
            'ADMIN'    => {
                'USERNAME' => $db_admin_username,
                'PASSWORD' => $db_admin_password,
            },
        },
        'SQLALCHEMY_ENGINE_OPTIONS' => {
            # trove tends to kill db sessions at 120s of age,
            # unlike default mariadb at 300s
            'pool_recycle' => 90,
        },
        'OPENSTACK' => {
            'CONFIG' => '/etc/novaobserver.yaml',
        },
    }

    file { $config_file:
        ensure  => file,
        content => to_yaml($config),
        notify  => Uwsgi::App['prometheus-manager'],
    }

    # Needed for prometheus exporter to share metrics between uwsgi processes
    file { $metrics_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }
    systemd::tmpfile { 'prometheus-manager-shared-metrics':
        content => "d ${metrics_dir} 0755 www-data www-data",
    }

    # TODO: better deployment model (scap, debian, so on) - T288052
    git::clone { 'cloud/metricsinfra/prometheus-manager':
        ensure    => latest,
        directory => $clone_dir,
        owner     => 'www-data',
        group     => 'www-data',
        notify    => [
            Uwsgi::App['prometheus-manager'],
            Exec['prometheus-manager-venv-install'],
            Exec['prometheus-manager-migrate'],
        ],
    }

    # the software uses some packages not in debian repos,
    # so we need to do some ugly venv trickery (based on Quarry's manifests).
    # the relevant pypi-only packages are as of writing:
    #  * flask-alembic
    #  * prometheus-flask-exporter
    #  * sqlalchemy-json
    ensure_packages(['python3-venv'])
    exec { 'prometheus-manager-venv':
        user    => 'www-data',
        command => "/usr/bin/python3 -m venv ${venv_dir}",
        creates => $venv_dir,
        require => Git::Clone['cloud/metricsinfra/prometheus-manager'],
        notify  => Exec['prometheus-manager-venv-update-pip-wheel'],
    }
    exec { 'prometheus-manager-venv-update-pip-wheel':
        user        => 'www-data',
        command     => "${venv_dir}/bin/pip install -U pip wheel",
        notify      => Exec['prometheus-manager-venv-install'],
        refreshonly => true,
    }
    exec { 'prometheus-manager-venv-install':
        user        => 'www-data',
        command     => "${venv_dir}/bin/pip install -e .",
        notify      => Uwsgi::App['prometheus-manager'],
        refreshonly => true,
    }

    $env = {
        # fix prometheus exporter for multiple uwsgi processes/workers
        'PROMETHEUS_MULTIPROC_DIR' => $metrics_dir,

        # location of our config file
        'PROMETHEUS_MANAGER_CONFIG_PATH' => $config_file,
    }

    $env_array = $env.map |String $key, String $value| {
        "${key}=${value}"
    }

    uwsgi::app { 'prometheus-manager':
        settings => {
            uwsgi => {
                'plugins'   => 'python3',
                'socket'    => '/run/uwsgi/prometheus_manager.sock',
                'wsgi-file' => "${clone_dir}/wsgi.py",
                'chdir'     => $clone_dir,
                'callable'  => 'app',
                'master'    => true,
                'processes' => 4,
                'venv'      => $venv_dir,
                'env'       => $env_array,
            },
        },
    }

    # again, a better tool would be nice for deployment
    # automatically run database migrations after git updates
    exec { 'prometheus-manager-migrate':
        command     => "${venv_dir}/bin/python3 scripts/pm-migrate",
        cwd         => $clone_dir,
        environment => $env_array,
        user        => 'www-data',
        require     => [
            File[$config_file],
            Git::Clone['cloud/metricsinfra/prometheus-manager'],
        ],
        refreshonly => true,
    }

    nginx::site { 'prometheus-manager-web-nginx':
        require => Uwsgi::App['prometheus-manager'],
        content => template('profile/wmcs/metricsinfra/configserver/prometheus-manager.nginx.erb'),
    }

    systemd::timer::job { 'metricsinfra-maintain-projects':
        ensure      => present,
        description => 'Syncronize list of OpenStack projects monitored by metricsinfra',
        command     => "${venv_dir}/bin/python3 ${clone_dir}/scripts/pm-maintain-projects",
        user        => 'www-data',
        # every 20 minutes, so at minute :7, :27, :47
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:7/20:00'},
        environment => $env,
    }
}
