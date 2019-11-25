class profile::openstack::codfw1dev::nova::placement::service(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'profile::openstack::base::nova::placement::service':
        version             => $version,
    }
}
