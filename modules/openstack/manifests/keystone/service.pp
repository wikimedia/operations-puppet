# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/

class openstack::keystone::service(
    $active,
    $version,
    $token_driver,
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
    class { "openstack::keystone::service::${version}":
        keystone_host               => $keystone_host,
        osm_host                    => $osm_host,
        db_name                     => $db_name,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        db_max_pool_size            => $db_max_pool_size,
        admin_workers               => $admin_workers,
        public_workers              => $public_workers,
        ldap_hosts                  => $ldap_hosts,
        ldap_base_dn                => $ldap_base_dn,
        ldap_user_id_attribute      => $ldap_user_id_attribute,
        ldap_user_name_attribute    => $ldap_user_name_attribute,
        ldap_user_dn                => $ldap_user_dn,
        ldap_user_pass              => $ldap_user_pass,
        auth_protocol               => $auth_protocol,
        auth_port                   => $auth_port,
        wiki_status_page_prefix     => $wiki_status_page_prefix,
        wiki_status_consumer_token  => $wiki_status_consumer_token,
        wiki_status_consumer_secret => $wiki_status_consumer_secret,
        wiki_status_access_token    => $wiki_status_access_token,
        wiki_status_access_secret   => $wiki_status_access_secret,
        wiki_consumer_token         => $wiki_consumer_token,
        wiki_consumer_secret        => $wiki_consumer_secret,
        wiki_access_token           => $wiki_access_token,
        wiki_access_secret          => $wiki_access_secret,
    }

    group { 'keystone':
        ensure  => 'present',
        require => Package['keystone'],
    }

    user { 'keystone':
        ensure  => 'present',
        require => Package['keystone'],
    }

    if $token_driver == 'redis' {
        package { 'python-keystone-redis':
            ensure => 'present';
        }
    }

    $require = [
        Package['keystone'],
        Group['keystone'],
        User['keystone'],
    ]

    file {
        '/var/log/keystone':
            ensure  => 'directory',
            owner   => 'keystone',
            group   => 'www-data',
            mode    => '0775',
            require => $require;
        '/etc/keystone':
            ensure  => 'directory',
            owner   => 'keystone',
            group   => 'keystone',
            mode    => '0755',
            require => $require,
    }

    file {'/var/lib/keystone/keystone.db':
        ensure  => 'absent',
        require => Package['keystone'],
    }

    service { 'keystone':
        ensure  => $active,
        require => Package['keystone'];
    }
}
