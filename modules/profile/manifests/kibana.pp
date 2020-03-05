# vim:sw=4 ts=4 sts=4 et:

# == Class: profile::kibana
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
    $vhost         = lookup('profile::kibana::vhost'),
    $serveradmin   = lookup('profile::kibana::serveradmin'),
    $auth_type     = lookup('profile::kibana::auth_type'),
    $require_ssl   = lookup('profile::kibana::require_ssl', { 'default_value' => true }),
    $auth_realm    = lookup('profile::kibana::auth_realm', { 'default_value' => undef }),
    $auth_file     = lookup('profile::kibana::auth_file', { 'default_value' => undef }),
    $ldap_authurl  = lookup('profile::kibana::ldap_authurl', { 'default_value' => undef }),
    $ldap_binddn   = lookup('profile::kibana::ldap_binddn', { 'default_value' => undef }),
    $ldap_groups   = lookup('profile::kibana::ldap_groups', { 'default_value' => [] }),
) {

    class { 'kibana': }
    include profile::idp::client::httpd

    $httpd_base_modules = ['proxy_http',
                        'proxy',
                        'alias',
                        'headers',
                        'rewrite']

    if $auth_type == 'ldap' {
        $httpd_extra_modules = ['authnz_ldap']
        include ::passwords::ldap::production

        # FIXME: move this into hiera config
        $ldap_bindpass = $passwords::ldap::production::proxypass

    } elsif $auth_type == 'local' {
        $httpd_extra_modules = ['authz_groupfile', 'authz_user']

    } elsif $auth_type != 'none' {
        fail('profile::kibana::auth_type must be one of ldap, local, none')
    }

    $httpd_modules = concat($httpd_base_modules, $httpd_extra_modules)

    class { '::httpd':
        modules => $httpd_modules,
    }

    $apache_auth = template("profile/kibana/apache-auth-${auth_type}.erb")

    ferm::service { 'kibana_frontend':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    httpd::site { $vhost:
        content => template('profile/kibana/apache.conf.erb'),
    }
}
