# SPDX-License-Identifier: Apache-2.0
# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy (
) {
    class {'profile::hadoop::httpd':
        http_only     => true,
        extra_modules => ['ssl'],
    }
    require profile::analytics::httpd::utils
    require profile::hadoop::common

    $server_name = $::realm ? {
        'production' => 'yarn.wikimedia.org',
        'labs'       => "yarn-${::wmcs_project}.${::site}.wmnet",
    }

    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]
    $spark_history_server_address = $profile::hadoop::common::yarn_spark_history_server_address

    profile::idp::client::httpd::site{ 'yarn.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-yarn.erb',
        proxied_as_https => true,
        vhost_settings   => {
            'res_manager'                  => $resourcemanager_primary_host,
            'spark_history_server_address' => $spark_history_server_address,
        },
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
}
