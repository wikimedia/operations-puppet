# == Class profile::swap
# SWAP - Simple Web Analytics Platform
# Sets up a JupyterHub instance with WMF LDAP authentication
# and authorization in certain POSIX groups.
#
# == Parameters
#
#   [*ldap_groups*]
#       If given, users will authenticate with WMF ldap, and only be authorized
#       if they are in these groups.  Default wmf, nda
#
#   [*posix_groups*]
#       Users in these group will be allowed to log into JupyterHub.
#       Default: admin::groups in production, project-$labsproject in Cloud VPS.
#
class profile::swap(
    $ldap_groups  = hiera('profile::swap::allowed_ldap_groups', [
        'cn=nda,ou=groups,dc=wikimedia,dc=org',
        'cn=wmf,ou=groups,dc=wikimedia,dc=org',
    ]),
    $ldap_server = hiera('labsldapconfig')['hostname'],
    $posix_groups = hiera('admin::groups', undef),
) {
    # Lots of handy packages for analysis.
    class { '::statistics::packages': }

    # If posix groups are not given, then use labsproject in labs, or wikidev in production.
    $default_posix_groups = $::realm ? {
        'labs'       => ["project-${::labsproject}"],
        'production' => ['wikidev'],
    }
    $_posix_groups = $posix_groups ? {
        undef   => $default_posix_groups,
        default => $posix_groups
    }

    # Use a web_proxy in production, and include the researchers db password.
    if $::realm == 'production' {
        $web_proxy = "http://webproxy.${::site}.wmnet:8080"

        statistics::mysql_credentials { 'research':
            group => 'researchers',
        }
    }
    else {
        $web_proxy = undef
    }

    class { 'jupyterhub':
        ldap_server           => $ldap_server,
        ldap_bind_dn_template => 'uid={username},ou=people,dc=wikimedia,dc=org',
        # LDAP authenticate anyone in these groups.
        ldap_groups           => $ldap_groups,
        # But only allow those in these posix groups to log in to jupyterhub.
        posix_groups          => $_posix_groups,
        web_proxy             => $web_proxy,
    }
}
