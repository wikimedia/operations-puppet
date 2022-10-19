class profile::openstack::codfw1dev::nova::api::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    String $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain', {default_value => 'example.com'}),
    Boolean $public_apis = lookup('profile::openstack::codfw1dev::public_apis')
) {
    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::api::service':
        version     => $version,
        dhcp_domain => $dhcp_domain,
        public_apis => $public_apis,
    }
}
