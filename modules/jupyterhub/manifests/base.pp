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
    ensure_packages([
                    'npm',
                    'nodejs-legacy',
                    'python3-dev',
                    'build-essential',
                    'python3-pip',
                    'libmysqlclient-dev'])

    file { '/etc/jupyterhub':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
    }

    file { '/etc/jupyterhub/jupyterhub_config.py':
        ensure  => present,
        content => template('jupyterhub/jupyterhub_config.py.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0644',
    }

    base::service_unit { 'jupyterhub':
        systemd => true,
    }
}
