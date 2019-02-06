class openstack::keystone::service::mitaka(
    $keystone_host,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $db_max_pool_size,
    $public_workers,
    $admin_workers,
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
    class { "openstack::keystone::service::mitaka::${::lsbdistcodename}": }

    include ::network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    file {
        '/etc/logrotate.d/keystone':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/keystone/keystone_logrotate',
            require => Package['keystone'];
        '/etc/keystone/keystone.conf':
            ensure  => 'present',
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0444',
            content => template('openstack/mitaka/keystone/keystone.conf.erb'),
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/keystone/keystone-paste.ini',
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/policy.json':
            ensure  => 'present',
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/openstack/mitaka/keystone/policy.json',
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/mitaka/keystone/logging.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['keystone'],
            require => Package['keystone'];
        '/etc/keystone/keystone.my.cnf':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template('openstack/mitaka/keystone/keystone.my.cnf.erb');
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/keystone/wmfkeystoneauth',
            notify  => Service['keystone'],
            recurse => true;
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth.egg-info':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/mitaka/keystone/wmfkeystoneauth.egg-info',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['keystone'],
            recurse => true;
    }
}
