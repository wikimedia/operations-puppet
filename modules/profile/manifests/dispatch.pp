# SPDX-License-Identifier: Apache-2.0
# Class: profile::dispatch
#
# Set up dispatch frontend
#
# Actions:
#   deploy and configure Dispatch
#
# Sample Usage:
#   include profile::dispatch
#
# Parameters:
#   $active_host    Which (alertmanager) host is active
#   $db_hostname    DB to connect to
#   $db_password    DB password to use
#   $port           port to listen on
#   $version        the dispatch container version to deploy
#   $encryption_key the session encryption key to use
#   $env_extra      extra environment variables to set
#   $vhost          the Apache virtual host to answer on
#   $log_level      the dispatch log level
#   $ldap_config    the LDAP configuration ('ldap' global variable, for SSO)

class profile::dispatch (
    Stdlib::Host         $active_host        = lookup('profile::alertmanager::active_host'),
    String[1]            $db_hostname        = lookup('profile::dispatch::db_hostname'),
    String[1]            $db_password        = lookup('profile::dispatch::db_password'),
    Stdlib::Port::User   $port               = lookup('profile::dispatch::port', { 'default_value' => 8000 }),
    String[1]            $version            = lookup('profile::dispatch::version', { 'default_value' => 'latest' }),
    String[1]            $encryption_key     = lookup('profile::dispatch::encryption_key'),
    Hash[String, String] $env_extra          = lookup('profile::dispatch::env_extra', { 'default_value' => {} }),
    # lint:ignore:wmf_styleguide - T260574
    String $vhost                            = lookup('profile::dispatch::vhost', {'default_value' => "dispatch.${facts['domain']}"}),
    # lint:endignore
    Wmflib::Syslog::Level::Python $log_level = lookup('profile::dispatch::log_level', {'default_value' => 'INFO'}),
    Hash[String, String] $ldap_config        = lookup('ldap', {'merge' => 'hash'}),
) {
    require ::profile::docker::engine

    if $active_host == $::fqdn {
        $scheduler_ensure = present
    } else {
        $scheduler_ensure = absent
    }

    $final_env = deep_merge($env_extra, {
        'DISPATCH_AUTHENTICATION_PROVIDER_HEADER_NAME' => 'x-cas-mail',
        'DISPATCH_AUTHENTICATION_PROVIDER_SLUG'        => 'dispatch-auth-provider-header',
    })

    class { 'dispatch::web':
        db_hostname      => $db_hostname,
        db_password      => $db_password,
        port             => $port,
        encryption_key   => $encryption_key,
        version          => $version,
        env_extra        => $final_env,
        vhost            => $vhost,
        scheduler_ensure => $scheduler_ensure,
    }

    profile::idp::client::httpd::site { $vhost:
        document_root   => '/var/www/html',
        acme_chief_cert => 'icinga',
        vhost_content   => 'profile/idp/client/httpd-dispatch.erb',
        vhost_settings  => {
            dispatch_port => $port,
        },
        required_groups => [
            "cn=ops,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
            "cn=wmf,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
            "cn=nda,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
        ],
    }
}
