class profile::openstack::codfw1dev::nova::api::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $labs_hosts_range = lookup('profile::openstack::codfw1dev::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::codfw1dev::labs_hosts_range_v6'),
    String       $dhcp_domain               = lookup('profile::openstack::codfw1dev::nova::dhcp_domain',
                                                    {default_value => 'example.com'}),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
        dhcp_domain         => $dhcp_domain,
    }
}
