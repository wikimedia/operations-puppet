# == Class profile::analytics::jupyterhub
#
# Sets up JupyterHub for use in the Analytics Cluster.
# JupyterHub and JupyterLab run from jupyter-analytics. The kernels are user
# conda environments, cloned from conda-analytics.
#
# == Parameters
#
#   [*allowed_ldap_groups*]
#       If given, users will authenticate with WMF LDAP, and only be authorized
#       if they are in these groups.  Default wmf, nda
#
#   [*ldap_config*]
#       LDAP production config containing the read-only endpoint to use.

class profile::analytics::jupyterhub(
    Array[String] $allowed_ldap_groups  = lookup(
        'profile::analytics::jupyterhub::allowed_ldap_groups', default_value => [
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ]
    ),
    Hash $ldap_config                   = lookup('ldap'),
    Optional[String] $http_proxy_host   = lookup('http_proxy_host', default_value => undef),
    Optional[Integer] $http_proxy_port  = lookup('http_proxy_port', default_value => undef),
) {
    include profile::admin
    # Members of the admin groups of the host can log in. Hosts without admin groups use wikidev.
    $allowed_posix_groups = $profile::admin::groups.empty ? {
        true    => ['wikidev'],
        default => $profile::admin::groups
    }

    $jupyterhub_config = {
        'authenticator'            => 'ldap',
        'ldap_server'              => $ldap_config['ro-server'],
        'ldap_bind_dn_template'    => 'uid={username},ou=people,dc=wikimedia,dc=org',
        # LDAP authenticate anyone in these groups.
        'allowed_ldap_groups'      => $allowed_ldap_groups,
        # But only allow those in these posix groups to log in to jupyterhub.
        'allowed_posix_groups'     => $allowed_posix_groups,
        'external_http_proxy_host' => $http_proxy_host,
        'external_http_proxy_port' => $http_proxy_port,
    }

    class { 'jupyterhub':
        config => $jupyterhub_config,
    }

    # Remove the files of the old JupyterHub from conda-analytics.
    # TODO: Remove these resources when Puppet has run on all hosts. See T321512.
    systemd::syslog { 'jupyterhub-conda':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
    }
    file { ['/etc/jupyterhub-conda', '/srv/jupyterhub-conda']:
        ensure => absent,
        force  => true,
    }

    # Files deleted via the notebook interface are moved to a special
    # Trash directory and never removed.
    systemd::timer::job { 'clean_jupyter_user_local_trash':
        ensure      => present,
        description => 'Regular jobs to clear the trash directory',
        user        => 'root',
        command     => '/bin/bash -c \'for user in $(ls /srv/home); do rm -rf /srv/home/$user/.local/share/Trash/*; done\'',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    }
}
