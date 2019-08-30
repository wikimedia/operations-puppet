class profile::openstack::codfw1dev::haproxy(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::codfw1dev::nova_controller_standby'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::codfw1dev::nova::metadata_listen_port'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::codfw1dev::nova::osapi_compute_listen_port'),
) {
    profile::openstack::base::haproxy::site { 'neutron':
        servers       => [$nova_controller, $nova_controller_standby],
        port_frontend => 9696,
        port_backend  => $neutron_bind_port,
    }

    profile::openstack::base::haproxy::site { 'nova_api':
        servers       => [$nova_controller, $nova_controller_standby],
        port_frontend => 8774,
        port_backend  => $nova_osapi_compute_listen_port,
    }

    profile::openstack::base::haproxy::site { 'nova_metadata':
        servers       => [$nova_controller, $nova_controller_standby],
        port_frontend => 8775,
        port_backend  => $nova_metadata_listen_port,
    }
}
