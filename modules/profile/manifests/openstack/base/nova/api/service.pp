class profile::openstack::base::nova::api::service(
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    ) {

    class {'::openstack::nova::api::service':
        active => ($::fqdn == $nova_api_host),
    }

    class {'::openstack::nova::api::monitor':
        active => ($::fqdn == $nova_api_host),
    }
}
