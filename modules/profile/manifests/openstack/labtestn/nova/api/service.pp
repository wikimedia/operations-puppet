class profile::openstack::labtestn::nova::api::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    $labs_hosts_range = hiera('profile::openstack::labtestn::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::labtestn::labs_hosts_range_v6')
    ) {

    require ::profile::openstack::labtestn::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        nova_api_host       => $nova_api_host,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
    }
}
