# == Class profile::analytics::jupyterhub
#
# Sets up JupyterHub for use in the Analytics Cluster.
# This uses anaconda-wmf to create and use user conda environments.
#
# == Parameters
#
#   [*port*]
#       Port on which users should connect to JupyterHub.  Default 8880
#
#   [*allowed_ldap_groups*]
#       If given, users will authenticate with WMF LDAP, and only be authorized
#       if they are in these groups.  Default wmf, nda
#
#   [*ldap_config*]
#       LDAP production config containing the read-only endpoint to use.
#
#   [*allowed_posix_groups*]
#       Users in these groups will be allowed to log into JupyterHub.
#       Default: admin::groups in production, project-$wmcs_project in Cloud VPS.
#
#   [*admin_posix_groups*]
#       Users in these groups will be allowed admin access to JupyterHub.

class profile::analytics::jupyterhub(
    Integer $port                       = lookup(
        'profile::analytics::jupyterhub::port', default_value => 8880,
    ),
    Array[String] $allowed_ldap_groups  = lookup(
        'profile::analytics::jupyterhub::allowed_ldap_groups', default_value => [
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ]
    ),
    Hash $ldap_config                   = lookup('ldap', Hash, hash, {}),
    Array[String] $admin_posix_groups   = lookup('profile::analytics::jupyterhub::admin_posix_groups', default_value => ['ops']),
    Optional[String] $http_proxy_host   = lookup('http_proxy_host', default_value => undef),
    Optional[Integer] $http_proxy_port  = lookup('http_proxy_port', default_value => undef),
) {
    include profile::admin
    $allowed_posix_groups = $profile::admin::groups.empty ? {
        true    => ['wikidev'],
        default => $profile::admin::groups
    }


    class { 'jupyterhub::server':
        config => {
            'authenticator'            => 'ldap',
            'ldap_server'              => $ldap_config['ro-server'],
            'ldap_bind_dn_template'    => 'uid={username},ou=people,dc=wikimedia,dc=org',
            # LDAP authenticate anyone in these groups.
            'allowed_ldap_groups'      => $allowed_ldap_groups,
            # But only allow those in these posix groups to log in to jupyterhub.
            'allowed_posix_groups'     => $allowed_posix_groups,
            'external_http_proxy_host' => $http_proxy_host,
            'external_http_proxy_port' => $http_proxy_port,
        },
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
