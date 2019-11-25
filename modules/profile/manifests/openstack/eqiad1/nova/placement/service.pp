class profile::openstack::eqiad1::nova::placement::service(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Stdlib::Port $placement_api_port = lookup('profile::openstack::eqiad1::nova::placement_api_port'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::placement::service':
        version            => $version,
        placement_api_port => $placement_api_port,
    }
}
