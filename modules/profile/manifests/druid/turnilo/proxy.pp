# SPDX-License-Identifier: Apache-2.0
# == Class profile::druid::turnilo::proxy
#
# Sets up an apache http proxy with WMF ldap authentication.
# To login, you must be in either the wmf or ops ldap group.
#
# This class can only be used on the same host running turnilo.
#
# == Parameters
#
# [*server_name*]
#   VirtualHost ServerName hostname to use.
#
# [*turnilo_port*]
#   Port bound by the Turnilo nodejs service.
#
class profile::druid::turnilo::proxy(
    String $turnilo_port     = lookup('profile::turnilo::proxy::turnilo_port', { 'default_value' => '9091' }),
) {

    require ::profile::analytics::httpd::utils

    class { '::httpd':
        modules => ['proxy_http', 'proxy', 'auth_basic']
    }

    ferm::service { 'turnilo-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    profile::idp::client::httpd::site {'turnilo.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-turnilo.erb',
        proxied_as_https => true,
        vhost_settings   => { 'turnilo_port' => $turnilo_port },
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    profile::auto_restarts::service { 'apache2': }
}
