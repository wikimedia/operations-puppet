class profile::openstack::eqiad1::nova::placement::service(
    String $version = lookup('profile::openstack::eqiad1::version'),
    ) {

    require ::profile::openstack::eqiad1::nova::common
    class {'profile::openstack::base::nova::placement::service':
        version             => $version,
    }
}
