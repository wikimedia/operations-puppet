class profile::wmcs::metricsinfra::configserver (
    String $db_hostname       = lookup('profile::wmcs::metricsinfra::configserver::db_hostname', {default_value => 'wu5emp5wblz.svc.trove.eqiad1.wikimedia.cloud'}),
    String $db_database       = lookup('profile::wmcs::metricsinfra::configserver::db_database', {default_value => 'prometheusconfig'}),
    String $db_user_username  = lookup('profile::wmcs::metricsinfra::configserver::db_user_username', {default_value => 'configuser'}),
    String $db_user_password  = lookup('profile::wmcs::metricsinfra::configserver::db_user_password'),
    String $db_admin_username = lookup('profile::wmcs::metricsinfra::configserver::db_admin_username', {default_value => 'configadmin'}),
    String $db_admin_password = lookup('profile::wmcs::metricsinfra::configserver::db_admin_password'),
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
    }

    file { $config_file:
        ensure  => file,
        content => to_yaml($config),
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

    # TODO: better deployment model (scap, debian, so on)
    git::clone { 'cloud/metricsinfra/prometheus-manager':
        ensure    => latest,
        directory => $clone_dir,
        owner     => 'www-data',
        group     => 'www-data',
        notify    => [
            Uwsgi::App['prometheus-manager'],
            Exec['prometheus-manager-venv-requirements'],
            Exec['prometheus-manager-migrate'],
        ],
    }

    # there are some required packages not in debian repos,
    # so we need to do some ugly venv trickery.
    # the relevant pypi-only packages are as of writing:
    #  * flask-alembic
    #  * prometheus-flask-exporter
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
        notify      => Exec['prometheus-manager-venv-requirements'],
        refreshonly => true,
    }
    exec { 'prometheus-manager-venv-requirements':
        user        => 'www-data',
        command     => "${venv_dir}/bin/pip install -r ${clone_dir}/requirements.txt",
        notify      => Uwsgi::App['prometheus-manager'],
        refreshonly => true,
    }

    $env = [
        # TODO: investigate why this is needed
        "PYTHONPATH=${clone_dir}",

        # tell prometheus exporter to use the
        # directory for metrics between processes
        "PROMETHEUS_MULTIPROC_DIR=${metrics_dir}",

        # tell our application where the configuration lives
        "PROMETHEUS_MANAGER_CONFIG_PATH=${config_file}",
    ]

    uwsgi::app { 'prometheus-manager':
        settings => {
            uwsgi => {
                'plugins'   => 'python3',
                'socket'    => '/run/uwsgi/prometheus_manager.sock',
                'wsgi-file' => "${clone_dir}/wsgi.py",
                'callable'  => 'app',
                'master'    => true,
                'processes' => 4,
                'venv'      => $venv_dir,
                'env'       => $env,
            },
        },
    }

    # again, a better tool would be nice for deployment
    # automatically run database migrations after git updates
    exec { 'prometheus-manager-migrate':
        command     => "${venv_dir}/bin/python3 scripts/pm-migrate",
        cwd         => $clone_dir,
        environment => $env,
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
}
