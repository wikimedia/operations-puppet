class openstack::glance::service(
    $active,
    $version,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $ldap_user_pass,
    $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    String $ceph_pool,
    $glance_backends,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
) {

    class { "openstack::glance::service::${version}":
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        glance_data_dir             => $glance_data_dir,
        ldap_user_pass              => $ldap_user_pass,
        keystone_fqdn               => $keystone_fqdn,
        api_bind_port               => $api_bind_port,
        glance_backends             => $glance_backends,
        ceph_pool                   => $ceph_pool,
        memcached_nodes             => $memcached_nodes,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    file { $glance_data_dir:
        ensure  => directory,
        owner   => 'glance',
        group   => 'glance',
        require => Package['glance'],
        mode    => '0755',
    }

    service { 'glance-api':
        ensure  => $active,
        require => Package['glance'],
    }

    rsyslog::conf { 'glance':
        source   => 'puppet:///modules/openstack/glance/glance.rsyslog.conf',
        priority => 20,
    }
}
