# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy (
) {
    require profile::hadoop::httpd
    require profile::analytics::httpd::utils
    require profile::hadoop::common

    $server_name = $::realm ? {
        'production' => 'yarn.wikimedia.org',
        'labs'       => "yarn-${::wmcs_project}.${::site}.wmnet",
    }

    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]

    profile::idp::client::httpd::site{ 'yarn.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-yarn.erb',
        proxied_as_https => true,
        vhost_settings   => { 'res_manager' => $resourcemanager_primary_host },
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    profile::auto_restarts::service { 'apache2': }
}
