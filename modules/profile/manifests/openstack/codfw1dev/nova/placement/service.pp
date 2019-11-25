class profile::openstack::codfw1dev::nova::placement::service(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Port $placement_api_port = lookup('profile::openstack::codfw1dev::nova::placement_api_port'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::placement::service':
        version            => $version,
        placement_api_port => $placement_api_port,
    }
}
