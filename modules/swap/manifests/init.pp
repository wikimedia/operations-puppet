# == Class: swap
# Sets up a JupyterHub for WMF that spawns users with Systemd.
#
# Runs from a deployed virtualenv from analytics/swap/deploy,
# and also creates a virtualenv for each user as they log in.
# Also is hardened a little bit with various
# Systemd capabilities, but could use more!
#
# === Parameters
#
# [*port*]
#   JupyterHub port
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
#
# [*allowed_posix_groups*]
#   Default: wikidev
#
# [*allowed_ldap_groups*]
#   Default: nda and wmf
#
class swap (
    $default_jupyter      = 'notebook',
    $port                 = 8000,
    $authenticator        = 'ldap',
    $web_proxy            = undef,
    $allowed_posix_groups = ['wikidev'],
    $allowed_ldap_groups  = [
        'cn=nda,ou=groups,dc=wikimedia,dc=org',
        'cn=wmf,ou=groups,dc=wikimedia,dc=org',
    ],
    $deployment_user      = 'analytics_deploy',
)
{
    $venv_path    = '/srv/deployment/analytics/swap/venv'
    $wheels_path  = "/srv/deployment/analytics/swap/deploy/artifacts/${::lsbdistcodename}/wheels"
    $database_uri = 'sqlite:////srv/jupyterhub/data/jupyterhub.sqlite.db'

    require_package(
        'nodejs-legacy', # For embedded configurable-http-proxy
        'virtualenv',
        'python3-venv',
        # Packages for PDF exports
        'pandoc',
        'texlive-xetex',
        'texlive-fonts-recommended',
        'texlive-generic-recommended',
    )

    # scap::target { 'analytics/swap/deploy':
    #     deploy_user  => $deployment_user,
    #     service_name => 'jupyterhub',
    # }

    file { ['/etc/jupyterhub', '/srv/jupyterhub', '/srv/jupyterhub/data']:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/jupyterhub/jupyterhub_config.py':
        ensure  => present,
        content => template('swap/jupyterhub_config.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
    }

    # We generate our own cookie secret, since the hub can't actually write it
    exec { 'jupyterhub-make-cookie-secret':
        command     => '/usr/bin/openssl rand -hex 32 > /etc/jupyterhub/jupyterhub_cookie_secret',
        creates     => '/etc/jupyterhub/jupyterhub_cookie_secret',
        environment => 'RANDFILE=/etc/jupyterhub/.rnd',
        umask       => '0377',
        user        => 'root',
        group       => 'root',
        require     => File['/etc/jupyterhub'],
    }

    systemd::syslog { 'jupyterhub':
        readable_by => 'group',
        base_dir    => '/var/log',
        owner       => 'root',
        group       => 'root',
    }

    systemd::service { 'jupyterhub':
        content   => systemd_template('jupyterhub'),
        restart   => true,
        subscribe => [
            File['/etc/jupyterhub/jupyterhub_config.py'],
            Exec['jupyterhub-make-cookie-secret']
        ],
        require   => [
            # Scap::Target['analytics/swap/deploy'],
            Systemd::Syslog['jupyterhub'],
        ]
    }
}
