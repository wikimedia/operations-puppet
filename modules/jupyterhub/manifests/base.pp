# == Class: jupyterhub::base
# Base class for setting up JupyterHub - very WIP
#
class jupyterhub::base {
    ensure_packages([
                    'npm',
                    'nodejs-legacy',
                    'python3-dev',
                    'gcc',
                    'python3-pip'])

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
        groups  => 'www-data',
        mode    => '0644',
    }

    base::service_unit { 'jupyterhub':
        systemd => true,
    }
}
