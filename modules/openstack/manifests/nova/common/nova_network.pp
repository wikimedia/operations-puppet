class openstack::nova::common::nova_network(
    $version,
    $nova_controller,
    $nova_api_host,
    $nova_api_host_ip,
    $dmz_cidr,
    $dhcp_domain,
    $quota_floating_ips,
    $dhcp_start,
    $network_flat_interface,
    $flat_network_bridge,
    $fixed_range,
    $network_public_interface,
    $network_public_ip,
    $zone,
    $scheduler_pool,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $ldap_user_pass,
    $libvirt_type,
    $live_migration_uri,
    $glance_host,
    $rabbit_user,
    $rabbit_host,
    $rabbit_pass,
    $spice_hostname,
    $keystone_auth_uri,
    $keystone_admin_uri,
    ) {

    class {'openstack::nova::common::base':
        version => $version,
    }

    file {
        '/etc/nova/nova.conf':
            content => template("openstack/${version}/nova/common/nova_network/nova.conf.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
        '/etc/nova/api-paste.ini':
            content => template("openstack/${version}/nova/common/nova_network/api-paste.ini.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }
}
