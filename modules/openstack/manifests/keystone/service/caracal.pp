# SPDX-License-Identifier: Apache-2.0

class openstack::keystone::service::caracal(
    Array[Stdlib::Fqdn] $memcached_nodes,
    Integer $max_active_keys,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $public_workers,
    $admin_workers,
    $ldap_hosts,
    $ldap_rw_host,
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $region,
    String $keystone_admin_uri,
    $wiki_status_page_prefix,
    $wiki_status_consumer_token,
    $wiki_status_consumer_secret,
    $wiki_status_access_token,
    $wiki_status_access_secret,
    $wiki_consumer_token,
    $wiki_consumer_secret,
    $wiki_access_token,
    $wiki_access_secret,
    String $wsgi_server,
    String $wmcloud_domain_owner,
    String $bastion_project_id,
    Array[String] $prod_networks,
    Array[String] $labs_networks,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
    Stdlib::Fqdn $horizon_hostname,
) {
    class { "openstack::keystone::service::caracal::${::lsbdistcodename}":
        public_bind_port => $public_bind_port,
        admin_bind_port  => $admin_bind_port,
    }

    # Hint for conf sub-templates
    $version = 'caracal'

    file {
        '/etc/logrotate.d/keystone':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/caracal/keystone/keystone_logrotate',
            require => Package['keystone'];
        '/etc/keystone/keystone.conf':
            ensure    => 'present',
            owner     => 'keystone',
            group     => 'keystone',
            mode      => '0444',
            show_diff => false,
            content   => template('openstack/caracal/keystone/keystone.conf.erb'),
            notify    => Service[$wsgi_server],
            require   => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/caracal/keystone/keystone-paste.ini',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/policy.yaml':
            ensure  => 'present',
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/openstack/caracal/keystone/policy.yaml',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/caracal/keystone/logging.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/keystone.my.cnf':
            ensure    => 'present',
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
            content   => template('openstack/caracal/keystone/keystone.my.cnf.erb');
        '/usr/lib/python3/dist-packages/wmfkeystoneauth':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/caracal/keystone/wmfkeystoneauth',
            notify  => Service[$wsgi_server],
            recurse => true;
        '/usr/lib/python3/dist-packages/wmfkeystoneauth.egg-info':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/caracal/keystone/wmfkeystoneauth.egg-info',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service[$wsgi_server],
            recurse => true;
    }

    # Specify that the Default domain uses ldap (while the default /config/ specifies
    #  mysql. Confusing, right?)
    file {'/etc/keystone/domains/keystone.default.conf':
            ensure    => 'present',
            owner     => 'keystone',
            group     => 'keystone',
            mode      => '0444',
            show_diff => false,
            content   => template('openstack/caracal/keystone/keystone.default.conf.erb'),
            notify    => Service[$wsgi_server],
            require   => Package['keystone'];
    }

    # Map toolsbeta service users to keystone users in the 'toolsbeta' domain
    #  part of T358496
    file {'/etc/keystone/domains/keystone.toolsbeta.conf':
            ensure    => 'present',
            owner     => 'keystone',
            group     => 'keystone',
            mode      => '0444',
            show_diff => false,
            content   => template('openstack/caracal/keystone/keystone.toolsbeta.conf.erb'),
            notify    => Service[$wsgi_server],
            require   => Package['keystone'];
    }
}
