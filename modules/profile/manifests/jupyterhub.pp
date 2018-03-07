# == Class profile::jupyterhub
# Profile for setting up a Jupyterhub (SWAP) service.
#
class profile::jupyterhub(
    $sitename    = hiera('profile::jupyterhub::sitename', 'jupyterhub'),
    $base_path   = hiera('profile::jupyterhub::base_path', '/srv/jupyterhub'),
    $wheels_repo = hiera('profile::jupyterhub::wheels_repo', 'operations/wheels/paws-internal'),
    $ldap_groups = hiera('profile::jupyterhub::ldap_groups', ['cn=ops,ou=groups,dc=wikimedia,dc=org']),
    $web_proxy   = hiera('profile::jupyterhub::web_proxy', "http://webproxy.${::site}.wmnet:8080")
) {
    class { '::jupyterhub':
        base_path   => $base_path,
        wheels_repo => $wheels_repo,
        web_proxy   => $web_proxy,
    }

    class { '::jupyterhub::static':
        sitename    => $sitename,
        static_path => "${base_path}/static",
        url_prefix  => '/public',
        ldap_groups => $ldap_groups,
    }

    class { '::statistics::packages': }

    if $::realm == 'production' {
        statistics::mysql_credentials { 'research':
            group => 'researchers',
        }
    }
}
