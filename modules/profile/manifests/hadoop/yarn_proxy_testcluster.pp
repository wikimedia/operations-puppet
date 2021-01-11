# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy_testcluster (
    Hash $ldap_config        = lookup('ldap', Hash, hash, {}),
) {
    require profile::hadoop::httpd
    require ::profile::analytics::httpd::utils
    require ::profile::hadoop::common
    include ::passwords::ldap::production

    $ldap_server_primary = $ldap_config['ro-server']
    $ldap_server_fallback = $ldap_config['ro-server-fallback']
    $proxypass = $passwords::ldap::production::proxypass
    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]
    $server_name = 'yarn.wikimedia.org'

    httpd::site { 'yarn.wikimedia.org':
        content => template('profile/hadoop/yarn-testcluster.vhost.erb'),
    }

    if !defined(Base::Service_auto_restart['apache2']) {
        base::service_auto_restart { 'apache2': }
    }
}
