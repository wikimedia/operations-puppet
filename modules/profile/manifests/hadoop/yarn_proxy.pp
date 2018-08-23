# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy {
    include profile::hadoop::common

    class { '::apache::mod::proxy_http': }
    class { '::apache::mod::proxy': }
    class { '::apache::mod::proxy_html': }
    class { '::apache::mod::xml2enc': }
    class { '::apache::mod::auth_basic': }
    class { '::apache::mod::authnz_ldap': }
    class { '::apache::mod::headers': }
    class { '::passwords::ldap::production': }

    $proxypass = $passwords::ldap::production::proxypass

    $resourcemanager_primary_host = $profile::hadoop::common::resourcemanager_hosts[0]

    $server_name = $::realm ? {
        'production' => 'yarn.wikimedia.org',
        'labs'       => "yarn-${::labsproject}.${::site}.wmnet",
    }

    # Set up the VirtualHost
    apache::site { 'yarn.wikimedia.org':
        content => template('profile/hadoop/yarn.vhost.erb'),
    }

    ferm::service { 'yarn-http':
        proto => 'tcp',
        port  => '80',
    }
}
