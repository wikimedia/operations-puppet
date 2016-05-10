# == Class: jupyterhub::base
# Base class for setting up JupyterHub - very WIP
# Pip3 packages to be installed
# jupyterhub-ldapauthenticator
# jupyterhub-simplespawner (from github atm)
# jsonschema
# zmq?
# jupyterhub
# notebook

class jupyterhub::base {
    ensure_packages(['python3', 'python3-virtualenv', 'virtualenv'])

    $base_dir = '/srv/paws-internal'
    file { $base_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    git::clone { 'operations/wheels/paws-internal':
        ensure    => present,
        directory => "${base_dir}/wheels",
        owner     => 'root',
        group     => 'root',
        mode      => '0775',
        require   => File[$base_dir],
    }

    exec { 'setup-virtualenv':
        command => "/usr/bin/virtualenv -p python3 ${base_dir}/venv",
        creates => "${base_dir}/venv/bin/python3",
        require => File[$base_dir],
    }

    # Idempotant script that deploys jupyterhub to match the version
    # in the wheels repo
    file { '/usr/local/sbin/deploy-jupyterhub':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('jupyterhub/deploy-jupyterhub.erb'),
    }

    file { "${base_dir}/jupyterhub_config.py":
        ensure  => present,
        content => template('jupyterhub/jupyterhub_config.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
    }

    base::service_unit { 'jupyterhub':
        systemd => true,
    }
}
