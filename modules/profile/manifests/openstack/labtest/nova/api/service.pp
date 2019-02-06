class profile::openstack::labtest::nova::api::service(
    $version = hiera('profile::openstack::labtest::version'),
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::labtest::labs_hosts_range_v6')
    ) {

    require ::profile::openstack::labtest::nova::common
    class {'::profile::openstack::base::nova::api::service':
        version             => $version,
        nova_api_host       => $nova_api_host,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
    }
    contain '::profile::openstack::base::nova::api::service'

    class {'::openstack::nova::api::monitor':
        active   => ($::fqdn == $nova_api_host),
    }
    contain '::openstack::nova::api::monitor'
}
