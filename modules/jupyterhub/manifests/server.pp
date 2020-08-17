# == Class: jupyterhub::server
# Sets up a JupyterHub server for WMF that spawns jupyterhub-singleuser processes
# in conda environemnts with Systemd.
# Uses the anaconda-wmf package as the base environment from which to spawn
# new user conda environments.
#
# NOTE: This class is deprecating the jupyterhub class in init.pp
# === Parameters
#
# [*config*]
#   A hash of string key,val pairs to provide to jupyterhub_config.py.
#   These are better documented in jupyterhub_config.py.
#
class jupyterhub::server (
    $config = {
        'port' => '8880'
    }
) {
    require_package('anaconda-wmf')

    # TODO: 'jupyterhub' is defined by the deprecated jupyterhub class in init.pp.
    # Rename it to 'jupyterhub' here when we remove the other one.
    $service_name = 'jupyterhub-conda'

    $base_path           = "/srv/${service_name}"
    $data_path           = "${base_path}/data"

    # TODO: rename this once old venv based jupyterhub is gone.
    $config_path         = "/etc/${service_name}"

    file { [$base_path, $data_path]:
        ensure => 'directory',
    }

    # Sync the files in files/config to $config_path.
    file { $config_path:
        ensure  => 'directory',
        recurse => true,
        source  => 'puppet:///modules/jupyterhub/config',
    }

    # I don't know why we need this on buster.
    $http_proxy_env_config = os_version('debian >= buster') ? {
        true => {
            'JUPYTERHUB_CONFIGURABLE_HTTP_PROXY_PID_FILE' =>
                "${data_path}/jupyterhub_configurable_http_proxy.pid"
        },
        default => {}
    }

    $default_config = {
        'conda_base_env_path' => '/usr/lib/anconda-wmf',
        'cookie_secret_file'  => "${data_path}/jupyterhub_cookie_secret",
        'db_url'              => "sqlite:///${data_path}/jupyterhub.sqlite.db",
    }

    # This will be rendered as key,val pairs in a dict in jupyterhub_config.py.
    $jupyterhub_config = merge(
        $default_config,
        $http_proxy_env_config,
        $config
    )

    # Render the jupyterhub_config.py template.
    $jupyterhub_config_file = "${config_path}/jupyterhub_config.py"
    file { $jupyterhub_config_file:
        content => template('jupyterhub/config/jupyterhub_config.py.erb'),
    }

    # Generate a cookie secret.
    exec { 'jupyterhub_cookie_secret_generate':
        command     => "/usr/bin/openssl rand -hex 32 > ${data_path}/jupyterhub_cookie_secret",
        creates     => "${data_path}/jupyterhub_cookie_secret",
        environment => "RANDFILE=${data_path}/.rnd",
        umask       => '0377',
        user        => 'root',
        group       => 'root',
        require     => File[$data_path],
    }


    systemd::syslog { $service_name:
        readable_by => 'group',
        base_dir    => '/var/log',
        owner       => 'root',
        group       => 'root',
    }

    systemd::service { $service_name:
        content   => systemd_template($service_name),
        restart   => true,
        subscribe => [
            File[$config_path],
            File[$jupyterhub_config_file],
            Exec['jupyterhub_cookie_secret_generate']
        ],
        require   => [
            Systemd::Syslog[$service_name],
        ]
    }
}
