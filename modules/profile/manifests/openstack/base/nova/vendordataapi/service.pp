class profile::openstack::base::nova::vendordataapi::service(
    String $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $vendordata_bind_port = lookup('profile::openstack::base::nova::vendordata_listen_port'),
    String $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    ) {

    class {'::openstack::nova::vendordataapi::service':
        version              => $version,
        vendordata_bind_port => $vendordata_bind_port,
        dhcp_domain          => $dhcp_domain,
        keystone_fqdn        => $keystone_api_fqdn,
        ldap_user_pass       => $ldap_user_pass,
    }
}
