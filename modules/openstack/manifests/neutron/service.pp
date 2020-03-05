class openstack::neutron::service(
    Boolean $active,
    $version,
    Stdlib::Port $bind_port,
    ) {

    class { "openstack::neutron::service::${version}":
        active    => $active,
        bind_port => $bind_port,
    }
}
