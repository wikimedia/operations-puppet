# == Class: jupyterhub::base
# Base class for setting up JupyterHub

class jupyterhub::base ($wheels_repo_url, $base_dir = '/srv/jupyterhub',) {

    ensure_packages([
                    'lua-cjson',
                    'python3',
                    'python3-virtualenv',
                    'virtualenv',
                    ])

    package { 'nginx-common':
        ensure => '1.9.10-1~bpo8+3',
    }

    package { 'nginx-extras':
        ensure  => '1.9.10-1~bpo8+3',
        require => Package['nginx-common'],
    }

    file { $base_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    git::clone { 'wheels-repo':
        ensure    => present,
        origin    => $wheels_repo_url,
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
        content => template('jupyterhub/deploy-jupyterhub.sh.erb'),
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
