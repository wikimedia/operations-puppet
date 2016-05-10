# == Class: jupyterhub::base
# Base class for setting up JupyterHub

class jupyterhub::base ($wheels_repo_url, $base_dir = '/srv/jupyterhub',) {

    # include jupyterhub::systemd

    ensure_packages([
                    'lua-cjson',
                    'python3',
                    'python3-virtualenv',
                    'virtualenv',
                    'pwgen',
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

    $venv_path = "${base_dir}/venv"

    exec { 'setup-virtualenv':
        command => "/usr/bin/virtualenv -p python3 ${venv_path}",
        creates => "${venv_path}/bin/python3",
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

    # Isolate all the things that we'll need to *write* to into this dir.
    # This allows us to restrict our readwrite access for the hub process into just this
    file { "${venv_path}/data":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    base::service_unit { 'jupyterhub':
        systemd => true,
    }

    base::service_unit { 'nchp':
        systemd => true,
    }

    file { "${venv_path}/nchp_config.py":
        ensure  => present,
        content => template('jupyterhub/nchp_config.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Base::Service_unit['nchp'],
        require => Exec['setup-virtualenv'],
    }

    file { "${venv_path}/jupyterhub_config.py":
        ensure  => present,
        content => template('jupyterhub/jupyterhub_config.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        notify  => Base::Service_unit['jupyterhub'],
        require => Exec['setup-virtualenv']
    }

    exec { "${name}-make-configproxy_auth_token":
        command => "/bin/echo CONFIGPROXY_AUTH_TOKEN=`/usr/bin/pwgen --secure -1 64` > ${venv_path}/configproxy_auth_token",
        creates => "${venv_path}/configproxy_auth_token",
        umask   => '0377',
        user    => 'root',
        group   => 'root',
        notify  => [
            Base::Service_unit['nchp'],
            Base::Service_unit['jupyterhub'],
        ],
    }

    # We generate our own cookie secret, since the hub can't actually write to $venv_path
    exec { "${name}-make-cookie-secret":
        command => "/usr/bin/pwgen --secure -1 128 > ${venv_path}/jupyterhub_cookie_secret",
        creates => "${venv_path}/jupyterhub_cookie_secret",
        umask   => '0377',
        user    => 'root',
        group   => 'root',
        notify  => Base::Service_unit['jupyterhub'],
    }

}
