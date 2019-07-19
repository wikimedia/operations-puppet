# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy {
    require profile::hadoop::common
    require profile::hadoop::httpd
    require ::profile::analytics::httpd::utils
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]

    $server_name = $::realm ? {
        'production' => 'yarn.wikimedia.org',
        'labs'       => "yarn-${::labsproject}.${::site}.wmnet",
    }

    # Set up the VirtualHost
    httpd::site { 'yarn.wikimedia.org':
        content => template('profile/hadoop/yarn.vhost.erb'),
        require => File['/var/www/health_check'],
    }
}
