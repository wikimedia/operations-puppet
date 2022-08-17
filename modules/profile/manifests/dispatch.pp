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

    $registry = 'docker-registry.wikimedia.org'
    $image = 'dispatch'

    $env_base = {
        'DISPATCH_ENCRYPTION_KEY' => $encryption_key,
        'DATABASE_HOSTNAME' => $db_hostname,
        'DATABASE_CREDENTIALS' => "dispatch:${db_password}",
        'DISPATCH_UI_URL' => "https://${vhost}",
        'LOG_LEVEL' => $log_level,
    }

    $env = deep_merge($env_base, $env_extra)

    $wrapper = @("WRAPPER")
    #!/bin/sh
    docker run --env-file /etc/dispatch/env --network host ${registry}/${image}:${version} $@
    | WRAPPER

    file { '/usr/local/bin/dispatch':
        content => $wrapper,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    service::docker { 'dispatch':
        image_name   => $image,
        version      => $version,
        port         => $port, # ignored when in host_network mode
        environment  => $env,
        host_network => true,
        override_cmd => "server start dispatch.main:app --port ${port}",
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

    service::docker { 'dispatch-scheduler':
        image_name   => $image,
        version      => $version,
        port         => $port, # ignored when in host_network mode
        environment  => $env,
        host_network => true,
        override_cmd => 'scheduler start',
    }
}
