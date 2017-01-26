# == Class: jupyterhub
# Sets up a simple JupyterHub that spawns users with Systemd
#
# Sets itself up from Wheels into a virtualenv, and creates a virtualenv
# for each user as they log in. Also is hardened a little bit with various
# Systemd capabilities, but could use more!
#
# === Parameters
#
# [*wheels_repo*]
#  Repo name from which to clone wheels.
#  Takes all the formats that `git::clone` takes
#
# [*base_path*]
#  The base path under which virtualenv, data and wheel directories are set
#
# [*authenticator*]
#  'dummy' to use DummyAuthenticator, which lets in anyone with any username
#  and password, as long as they already have a user account setup on the
#  machine. On labs, this means anyone with labs account.
#  'ldap' to use LDAPAuthenticator, configured to let only people with LDAP
#  credentials in. Currently restricted to members of the ops group only.
#
# [*web_proxy*]
#  Set this to put http/https_proxy environment variables in the spawned
#  single user servers.
class jupyterhub (
    $wheels_repo,
    $base_path='/srv/jupyterhub',
    $authenticator='ldap',
    $web_proxy=undef,
) {

    $venv_path = "${base_path}/venv"
    $wheels_path = "${base_path}/wheels"
    $data_path = "${base_path}/data"

    ensure_packages([
                    'lua-cjson',
                    'python3',
                    'python3-venv',
                    'pwgen',
                    ])

    package { 'nginx-common':
        ensure => '1.9.10-1~bpo8+3',
    }

    package { 'nginx-extras':
        ensure  => '1.9.10-1~bpo8+3',
        require => Package['nginx-common'],
    }

    file { $base_path:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    git::clone { $wheels_repo:
        ensure    => present,
        directory => $wheels_path,
        owner     => 'root',
        group     => 'root',
        mode      => '0775',
        require   => File[$base_path],
    }


    exec { 'setup-virtualenv':
        command => "/usr/bin/python3 -m venv ${venv_path}",
        creates => "${venv_path}/bin/python3",
        require => File[$base_path],
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
    file { $data_path:
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
        source  => 'puppet:///modules/jupyterhub/nchp_config.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Base::Service_unit['nchp'],
        require => Exec['setup-virtualenv'],
    }

    file { "${venv_path}/jupyterhub_config.py":
        ensure  => present,
        source  => 'puppet:///modules/jupyterhub/jupyterhub_config.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        notify  => Base::Service_unit['jupyterhub'],
        require => Exec['setup-virtualenv'],
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
