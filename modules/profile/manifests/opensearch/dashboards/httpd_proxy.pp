# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:

# == Class: profile::opensearch::dashboards::httpd_proxy
#
# Provisions Authentication for OpenSearch Dashboards
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
class profile::opensearch::dashboards::httpd_proxy (
    String                      $vhost        = lookup('profile::opensearch::dashboards::httpd_proxy::vhost'),
    String                      $serveradmin  = lookup('profile::opensearch::dashboards::httpd_proxy::serveradmin'),
    Enum['ldap','local','none'] $auth_type    = lookup('profile::opensearch::dashboards::httpd_proxy::auth_type'),
    Boolean                     $require_ssl  = lookup('profile::opensearch::dashboards::httpd_proxy::require_ssl',  { 'default_value' => true }),
    Optional[String]            $auth_realm   = lookup('profile::opensearch::dashboards::httpd_proxy::auth_realm',   { 'default_value' => undef }),
    Optional[String]            $auth_file    = lookup('profile::opensearch::dashboards::httpd_proxy::auth_file',    { 'default_value' => undef }),
    Optional[String]            $ldap_authurl = lookup('profile::opensearch::dashboards::httpd_proxy::ldap_authurl', { 'default_value' => undef }),
    Optional[String]            $ldap_binddn  = lookup('profile::opensearch::dashboards::httpd_proxy::ldap_binddn',  { 'default_value' => undef }),
    Optional[Array[String]]     $ldap_groups  = lookup('profile::opensearch::dashboards::httpd_proxy::ldap_groups',  { 'default_value' => [] }),
) {
    $httpd_base_modules = [
        'proxy_http',
        'proxy',
        'alias',
        'headers',
        'rewrite'
    ]

    if $auth_type == 'ldap' {
        $httpd_extra_modules = ['authnz_ldap']
        include ::passwords::ldap::production

        # FIXME: move this into hiera config
        $ldap_bindpass = $passwords::ldap::production::proxypass

    } elsif $auth_type == 'local' {
        $httpd_extra_modules = ['authz_groupfile', 'authz_user']

    } elsif $auth_type == 'none' {
        $httpd_extra_modules = []

    }

    $httpd_modules = concat($httpd_base_modules, $httpd_extra_modules)

    class { '::httpd':
        modules => $httpd_modules,
    }

    $apache_auth = template("profile/opensearch/dashboards/httpd_proxy/apache-auth-${auth_type}.erb")

    if $auth_type != 'none' {
      ferm::service { 'opensearch_dashboards_frontend':
          proto   => 'tcp',
          port    => 80,
          notrack => true,
          srange  => '$DOMAIN_NETWORKS',
      }
    }

    httpd::site { $vhost:
        content => template('profile/opensearch/dashboards/httpd_proxy/apache.conf.erb'),
    }
}
