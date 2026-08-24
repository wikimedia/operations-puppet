# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:

# == Class: profile::opensearch::api::httpd_proxy
#
# Provisions the httpd reverse proxy for OpenSearch API
#
# == Parameters:
# - $vhost: Apache vhost name
# - $serveradmin: Email address for contacting server administrator
# - $auth_type: Vhost auth type. One of ldap, local, local-api, none
# - $accounts: hash of username -> htpasswd-hashed password for authentication
# - $manage_local_users: Toggle for whether or not puppet should manage the htpasswd and htgroup files
# - $require_ssl: Require SSL connection to vhost?
# - $auth_realm: HTTP basic auth realm description
# - $auth_file: Path to where the htpasswd file should exist on disk for local auth types
# - $group_file: Path to where the htgroup file should exit on disk for local auth types
# - $install_httpd_mods: Toggle for whether or not this class should install httpd modules
# - $use_tls_endpoint: Configures apache to connect to OpenSearch using TLS
#
# filtertags: labs-project-deployment-prep
class profile::opensearch::api::httpd_proxy (
    String                      $vhost              = lookup('profile::opensearch::api::httpd_proxy::vhost'),
    String                      $serveradmin        = lookup('profile::opensearch::api::httpd_proxy::serveradmin'),
    Pattern[/^local/, /^none$/] $auth_type          = lookup('profile::opensearch::api::httpd_proxy::auth_type'),
    Hash[String, String]        $accounts           = lookup('profile::opensearch::api::httpd_proxy::accounts',           { 'default_value' => {} }),
    Hash[String, String]        $groups             = lookup('profile::opensearch::api::httpd_proxy::groups',             { 'default_value' => {} }),
    Boolean                     $manage_local_users = lookup('profile::opensearch::api::httpd_proxy::manage_local_users', { 'default_value' => true }),
    Boolean                     $require_ssl        = lookup('profile::opensearch::api::httpd_proxy::require_ssl',        { 'default_value' => true }),
    Optional[String]            $auth_realm         = lookup('profile::opensearch::api::httpd_proxy::auth_realm',         { 'default_value' => undef }),
    Optional[String]            $auth_file          = lookup('profile::opensearch::api::httpd_proxy::auth_file',          { 'default_value' => undef }),
    Optional[String]            $group_file         = lookup('profile::opensearch::api::httpd_proxy::group_file',         { 'default_value' => undef }),
    Boolean                     $install_httpd_mods = lookup('profile::opensearch::api::httpd_proxy::install_httpd_mods', { 'default_value' => true }),
    Boolean                     $use_tls_endpoint   = lookup('profile::opensearch::api::httpd_proxy::use_tls_endpoint',   { 'default_value' => false }),
) {
    $httpd_base_modules = $use_tls_endpoint ? {
        true    => ['ssl'],
        default => [],
    }

    if $auth_type =~ /^local/ {
        $httpd_extra_modules = ['authz_groupfile', 'authz_user']
        if $manage_local_users {
            file { $auth_file:
                ensure  => present,
                mode    => '0400',
                owner   => 'www-data',
                group   => 'www-data',
                content => ($accounts.map |$k, $v| { "${k}:${v}" } + ['']).join("\n"),
            }
            file { $group_file:
                ensure  => present,
                mode    => '0400',
                owner   => 'www-data',
                group   => 'www-data',
                content => ($groups.map |$k, $v| { "${k}:${v}" } + ['']).join("\n"),
            }
        }
    } elsif $auth_type == 'none' {
        $httpd_extra_modules = []
        file { $auth_file:
            ensure  => absent,
        }
        file { $group_file:
            ensure  => absent,
        }
    }

    if $install_httpd_mods {
        httpd::mod_conf { concat($httpd_base_modules, $httpd_extra_modules):
            ensure => present,
        }
    }

    $apache_auth = template("profile/opensearch/common/httpd_proxy/apache-auth-${auth_type}.erb")
    $locationmatch_search_endpoint = $auth_type == 'local-api' ? {
        true    => template('profile/opensearch/common/httpd_proxy/locationmatch_search_endpoint.erb'),
        default => ''
    }

    httpd::site { $vhost:
        content => template('profile/opensearch/api/httpd_proxy/apache.conf.erb'),
    }
}
