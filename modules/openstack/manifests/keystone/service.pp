# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/

class openstack::keystone::service(
    $active,
    $version,
    $nova_controller,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $token_driver,
    $ldap_hosts,
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $auth_protocol,
    $auth_port,
    $wiki_status_page_prefix,
    $wiki_status_consumer_token,
    $wiki_status_consumer_secret,
    $wiki_status_access_token,
    $wiki_status_access_secret,
    $wiki_consumer_token,
    $wiki_consumer_secret,
    $wiki_access_token,
    $wiki_access_secret,
    ) {

    include ::network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    package { 'keystone':
        ensure  => present,
    }
    package { 'python-oath':
        ensure  => present,
    }
    package { 'python-mysql.connector':
        ensure  => present,
    }

    if $token_driver == 'redis' {
        package { 'python-keystone-redis':
            ensure => present;
        }
    }

    file {
        '/var/log/keystone':
            ensure => directory,
            owner  => 'keystone',
            group  => 'www-data',
            mode   => '0775';
        '/etc/keystone':
            ensure => directory,
            owner  => 'keystone',
            group  => 'keystone',
            mode   => '0755';
        '/etc/keystone/keystone.conf':
            content => template("openstack/${version}/keystone/keystone.conf.erb"),
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0444',
            require => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            source  => "puppet:///modules/openstack/${version}/keystone/keystone-paste.ini",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package['keystone'];
        '/etc/keystone/policy.json':
            source  => "puppet:///modules/openstack/${version}/keystone/policy.json",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            source  => "puppet:///modules/openstack/${version}/keystone/logging.conf",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth':
            source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystoneauth",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            recurse => true;
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth.egg-info':
            source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystoneauth.egg-info",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            recurse => true;
    }

    service { 'keystone':
        ensure  => $active,
        require => Package['keystone'];
    }
}
