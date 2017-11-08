# vim:sw=4 ts=4 sts=4 et:

# == Class: role::kibana
#
# Provisions Kibana
#
# == Parameters:
# - $vhost: Apache vhost name
# - $serveradmin: Email address for contacting server administrator
# - $auth_type: Vhost auth type. One of ldap, local, none
# - $require_ssl: Require SSL connection to vhost?
# - $auth_realm: HTTP basic auth realm description
# - $auth_file: Path to htpasswd file for $auth_type == 'local'
# - $ldap_authurl: AuthLDAPURL for $auth_type == 'ldap'
# - $ldap_binddn: AuthLDAPBindDN for $auth_type == 'ldap'
# - $ldap_groups: List of ldap-group names for $auth_type == 'ldap'
#
# filtertags: labs-project-deployment-prep
class profile::kibana (
    $vhost        = hiera('profile::kibana::vhost'),
    $serveradmin  = hiera('profile::kibana::serveradmin'),
    $auth_type    = hiera('profile::kibana::auth_type'),
    $require_ssl  = hiera('profile::kibana::require_ssl', true),
    $auth_realm   = hiera('profile::kibana::auth_realm', ''),
    $auth_file    = hiera('profile::kibana::auth_file', ''),
    $ldap_authurl = hiera('profile::kibana::ldap_authurl', ''),
    $ldap_binddn  = hiera('profile::kibana::ldap_binddn', ''),
    $ldap_groups  = hiera('profile::kibana::ldap_groups', []),
) {
    class { '::apache': }
    class { '::apache::mod::alias': }
    class { '::apache::mod::headers': }
    class { '::apache::mod::proxy': }
    class { '::apache::mod::proxy_http': }
    class { '::apache::mod::rewrite': }
    class { '::kibana': }

    if $auth_type == 'ldap' {
        class { '::apache::mod::authnz_ldap': }
        class { '::passwords::ldap::production': }

        # FIXME: move this into hiera config
        $ldap_bindpass = $passwords::ldap::production::proxypass

    } elsif $auth_type == 'local' {
        class { '::apache::mod::authz_groupfile': }
        class { '::apache::mod::authz_user': }

    } elsif $auth_type != 'none' {
        fail('role::kibana::auth_type must be one of ldap, local, none')
    }

    $apache_auth = template("profile/kibana/apache-auth-${auth_type}.erb")

    ferm::service { 'kibana_frontend':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    apache::site { $vhost:
        content => template('profile/kibana/apache.conf.erb'),
    }
}
