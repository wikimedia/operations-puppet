# SPDX-License-Identifier: Apache-2.0
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
    ensure_packages('anaconda-wmf')

    # TODO: 'jupyterhub' is defined by the deprecated jupyterhub class in init.pp.
    # Rename it to 'jupyterhub' here when we remove the other one.
    $service_name = 'jupyterhub-conda'

    $base_path           = "/srv/${service_name}"
    $data_path           = "${base_path}/data"

    # TODO: rename this once old venv based jupyterhub is gone.
    $config_path         = "/etc/${service_name}"

    file { [$base_path, $data_path, $config_path]:
        ensure => 'directory',
    }

    # spawners.py contains our custom CondaEnvProfilesSpawner.
    file { "${config_path}/spawners.py":
        source => 'puppet:///modules/jupyterhub/config/spawners.py',
        mode   => '0444',
    }

    # This launches jupyterhub-singleuser from the specified conda env.
    file { "${config_path}/jupyterhub-singleuser-conda-env.sh":
        source => 'puppet:///modules/jupyterhub/config/jupyterhub-singleuser-conda-env.sh',
        mode   => '0555',
    }

    $default_config = {
        'conda_base_env_prefix' => '/usr/lib/anaconda-wmf',
        'cookie_secret_file'    => "${data_path}/jupyterhub_cookie_secret",
        'db_url'                => "sqlite:///${data_path}/jupyterhub.sqlite.db",
        'proxy_pid_file'        => "${data_path}/jupyterhub-proxy.pid",
    }

    # This will be rendered as key,val pairs in a dict in jupyterhub_config.py.
    $jupyterhub_config = merge(
        $default_config,
        $config
    )

    # Render the jupyterhub_config.py template.
    $jupyterhub_config_file = "${config_path}/jupyterhub_config.py"
    file { $jupyterhub_config_file:
        content => template('jupyterhub/config/jupyterhub_config.py.erb'),
        mode    => '0444',
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

    # jupyter_notebook_config.py configures global settings for all user Notebook Servers.
    # Currently this only configures the Notebook Terminal app to work nicely with
    # a sourced stacked conda environment.
    $jupyter_notebook_config_file = '/etc/jupyter/jupyter_notebook_config.py'
    file { $jupyter_notebook_config_file:
        source => 'puppet:///modules/jupyterhub/config/jupyter_notebook_config.py',
        mode   => '0444',
    }

    systemd::syslog { $service_name:
        readable_by            => 'group',
        base_dir               => '/var/log',
        owner                  => 'root',
        group                  => 'root',
        force_stop             => true,
        programname_comparison => 'isequal',
    }

    systemd::service { $service_name:
        content   => systemd_template($service_name),
        restart   => true,
        subscribe => [
            File[$jupyterhub_config_file],
            File["${config_path}/spawners.py"],
            Exec['jupyterhub_cookie_secret_generate']
        ],
        require   => [
            Systemd::Syslog[$service_name],
        ]
    }
}
