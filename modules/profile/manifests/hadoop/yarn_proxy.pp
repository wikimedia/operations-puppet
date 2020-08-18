# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy (
) {
    require profile::hadoop::httpd
    require ::profile::analytics::httpd::utils
    require ::profile::hadoop::common

    $server_name = $::realm ? {
        'production' => 'yarn.wikimedia.org',
        'labs'       => "yarn-${::labsproject}.${::site}.wmnet",
    }

    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]

    class {'profile::idp::client::httpd_legacy':
        vhost_settings => { 'res_manager' => $resourcemanager_primary_host },
    }
}
