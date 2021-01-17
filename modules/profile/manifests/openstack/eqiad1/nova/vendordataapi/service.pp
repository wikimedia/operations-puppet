class profile::openstack::eqiad1::nova::vendordataapi::service(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Stdlib::Port $vendordata_bind_port = lookup('profile::openstack::eqiad1::nova::vendordata_listen_port'),
    String $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    ) {

    class {'::profile::openstack::base::nova::vendordataapi::service':
        version              => $version,
        vendordata_bind_port => $vendordata_bind_port,
        dhcp_domain          => $dhcp_domain,
        keystone_api_fqdn    => $keystone_api_fqdn,
        ldap_user_pass       => $ldap_user_pass,
    }
}
