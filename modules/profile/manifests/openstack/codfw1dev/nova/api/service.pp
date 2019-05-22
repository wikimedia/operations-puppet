class profile::openstack::codfw1dev::nova::api::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $labs_hosts_range = hiera('profile::openstack::codfw1dev::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::codfw1dev::labs_hosts_range_v6')
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
    }
}
