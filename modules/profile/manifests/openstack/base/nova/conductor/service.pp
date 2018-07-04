class profile::openstack::base::nova::conductor::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    class {'::openstack::nova::conductor::service':
        version => $version,
        active  => $::fqdn == $nova_controller,
    }
    contain '::openstack::nova::conductor::service'
}
