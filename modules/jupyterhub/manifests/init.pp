# SPDX-License-Identifier: Apache-2.0
# == Class: jupyterhub
# Runs JupyterHub from the jupyter-analytics package. The hub uses systemd to
# start a single-user JupyterLab server for each user, also from jupyter-analytics.
# The user conda environments, cloned from conda-analytics, are the kernels.
#
# See T321512.
#
# === Parameters
#
# [*config*]
#   A hash of key, value pairs for jupyterhub_config.py. Puppet writes them to
#   config.json. jupyterhub_config.py documents the keys and their defaults.
#
class jupyterhub (
    Hash $config = {},
) {
    Class['conda_analytics'] -> Class['jupyterhub']

    $service_name  = 'jupyterhub'
    $prefix        = '/opt/jupyter-analytics'
    $base_path     = "/srv/${service_name}"
    $data_path     = "${base_path}/data"
    $config_path   = "/etc/${service_name}"
    $template_path = "${config_path}/templates"

    package { 'jupyter-analytics':
        ensure => present,
    }

    file { [$base_path, $config_path, "${config_path}/server_config"]:
        ensure => directory,
    }

    # The hub database and the cookie secret are here.
    file { $data_path:
        ensure => directory,
        mode   => '0700',
    }

    # Custom templates that extend the upstream JupyterHub templates.
    file { $template_path:
        ensure  => directory,
        source  => 'puppet:///modules/jupyterhub/templates',
        recurse => true,
        purge   => true,
    }

    file { "${config_path}/jupyterhub_config.py":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/jupyterhub_config.py',
        mode   => '0444',
    }

    # The spawner that lets users choose or create a conda environment.
    file { "${config_path}/wmf_spawner.py":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/wmf_spawner.py',
        mode   => '0444',
    }

    # The spawner runs this script to start the single-user server.
    file { "${config_path}/jupyterhub-singleuser.sh":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/jupyterhub-singleuser.sh',
        mode   => '0555',
    }

    # The launch script runs this to find the default kernel.
    file { "${config_path}/default_kernel_name.py":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/default_kernel_name.py',
        mode   => '0444',
    }

    # Settings for the single-user servers. The launch script adds this directory
    # to JUPYTER_CONFIG_PATH.
    file { "${config_path}/server_config/jupyter_server_config.py":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/jupyter_server_config.py',
        mode   => '0444',
    }

    # JupyterLab terminals read this file at start.
    file { "${config_path}/terminal_bashrc":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/terminal_bashrc',
        mode   => '0444',
    }

    # The conda kernels start with this script. It activates the conda environment.
    file { "${config_path}/conda_kernel_launcher.sh":
        source => 'puppet:///modules/jupyterhub/jupyter_analytics/conda_kernel_launcher.sh',
        mode   => '0555',
    }

    $default_config = {
        'conda_base_env_prefix'  => $conda_analytics::prefix,
        'jupyter_env_prefix'     => $prefix,
        'cookie_secret_file'     => "${data_path}/jupyterhub_cookie_secret",
        'db_url'                 => "sqlite:///${data_path}/jupyterhub.sqlite",
        'proxy_pid_file'         => "${data_path}/jupyterhub-proxy.pid",
        'template_path'          => $template_path,
        'singleuser_script'      => "${config_path}/jupyterhub-singleuser.sh",
        'server_config_dir'      => "${config_path}/server_config",
        'terminal_bashrc'        => "${config_path}/terminal_bashrc",
        'conda_kernel_launcher'  => "${config_path}/conda_kernel_launcher.sh",
    }
    $jupyterhub_config = stdlib::merge($default_config, $config)

    file { "${config_path}/config.json":
        content => $jupyterhub_config.stdlib::to_json_pretty(),
        mode    => '0444',
    }

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
            File["${config_path}/jupyterhub_config.py"],
            File["${config_path}/wmf_spawner.py"],
            File["${config_path}/config.json"],
            Exec['jupyterhub_cookie_secret_generate'],
        ],
        require   => [
            Package['jupyter-analytics'],
            Systemd::Syslog[$service_name],
        ],
    }
}
