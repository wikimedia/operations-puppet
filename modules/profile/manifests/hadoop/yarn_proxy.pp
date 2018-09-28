# Class: profile::hadoop::yarn_proxy
#
# Sets up a yarn ldap auth http proxy to the Hadoop ResourceManager web interface.
#
class profile::hadoop::yarn_proxy {
    include profile::hadoop::common

    # Ignore wmf styleguide; Need to include here as well as in profile/hue.pp
    # lint:ignore:wmf_styleguide
    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::proxy_html
    include ::apache::mod::xml2enc
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::passwords::ldap::production
    # lint:endignore

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
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
