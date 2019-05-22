class profile::openstack::eqiad1::nova::api::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::eqiad1::labs_hosts_range_v6')
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
    }
}
