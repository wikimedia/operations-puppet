class profile::openstack::base::nova::conductor::service(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::nova::conductor::service':
        version => $version,
        active  => true,
    }
    contain '::openstack::nova::conductor::service'
}
