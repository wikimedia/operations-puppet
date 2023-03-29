# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:

# == Class: profile::opensearch::api::httpd_proxy
#
# Provisions the httpd reverse proxy for OpenSearch API
#
# == Parameters:
# - $vhost: Apache vhost name
# - $serveradmin: Email address for contacting server administrator
# - $auth_type: Vhost auth type. One of ldap, local, none
# - $accounts: hash of username -> htpasswd-hashed password for authentication
# - $require_ssl: Require SSL connection to vhost?
# - $auth_realm: HTTP basic auth realm description
# - $auth_file: Path to htpasswd file for $auth_type == 'local'
#
# filtertags: labs-project-deployment-prep
class profile::opensearch::api::httpd_proxy (
    String                      $vhost        = lookup('profile::opensearch::api::httpd_proxy::vhost'),
    String                      $serveradmin  = lookup('profile::opensearch::api::httpd_proxy::serveradmin'),
    Enum['local','none']        $auth_type    = lookup('profile::opensearch::api::httpd_proxy::auth_type'),
    Hash[String, String]        $accounts     = lookup('profile::opensearch::api::httpd_proxy::accounts'),
    Boolean                     $require_ssl  = lookup('profile::opensearch::api::httpd_proxy::require_ssl',  { 'default_value' => true }),
    Optional[String]            $auth_realm   = lookup('profile::opensearch::api::httpd_proxy::auth_realm',   { 'default_value' => undef }),
    Optional[String]            $auth_file    = lookup('profile::opensearch::api::httpd_proxy::auth_file',    { 'default_value' => undef }),
) {
    if $auth_type == 'local' {
        $httpd_extra_modules = ['authz_groupfile', 'authz_user']
        file { $auth_file:
            ensure  => present,
            mode    => '0400',
            owner   => 'www-data',
            group   => 'www-data',
            content => ($accounts.map |$k, $v| { "${k}:${v}" } + ['']).join("\n"),
        }
    } elsif $auth_type == 'none' {
        $httpd_extra_modules = []
        file { $auth_file:
            ensure  => absent,
        }
    }

    httpd::mod_conf { $httpd_extra_modules:
        ensure => present,
    }

    $apache_auth = template("profile/opensearch/common/httpd_proxy/apache-auth-${auth_type}.erb")

    httpd::site { $vhost:
        content => template('profile/opensearch/api/httpd_proxy/apache.conf.erb'),
    }
}
