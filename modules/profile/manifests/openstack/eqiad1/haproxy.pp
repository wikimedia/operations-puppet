class profile::openstack::eqiad1::haproxy(
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::eqiad1::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::eqiad1::nova_controller_standby'),
    Stdlib::Port $glance_api_bind_port = lookup('profile::openstack::eqiad1::glance::api_bind_port'),
    Stdlib::Port $glance_registry_bind_port = lookup('profile::openstack::eqiad1::glance::registry_bind_port'),
    Stdlib::Port $keystone_admin_bind_port = lookup('profile::openstack::eqiad1::keystone::admin_bind_port'),
    Stdlib::Port $keystone_public_bind_port = lookup('profile::openstack::eqiad1::keystone::public_bind_port'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::eqiad1::nova::metadata_listen_port'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::eqiad1::nova::osapi_compute_listen_port'),
) {
    profile::openstack::base::haproxy::site { 'keystone_admin':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 35357,
        port_backend     => $keystone_admin_bind_port,
    }

    profile::openstack::base::haproxy::site { 'keystone_public':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 5000,
        port_backend     => $keystone_public_bind_port,
    }

    profile::openstack::base::haproxy::site { 'glance_api':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/healthcheck',
        port_frontend    => 9292,
        port_backend     => $glance_api_bind_port,
    }

    profile::openstack::base::haproxy::site { 'glance_registry':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/healthcheck',
        port_frontend    => 9191,
        port_backend     => $glance_registry_bind_port,
    }

    profile::openstack::base::haproxy::site { 'neutron':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 9696,
        port_backend     => $neutron_bind_port,
    }

    profile::openstack::base::haproxy::site { 'nova_api':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 8774,
        port_backend     => $nova_osapi_compute_listen_port,
    }

    profile::openstack::base::haproxy::site { 'nova_metadata':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 8775,
        port_backend     => $nova_metadata_listen_port,
    }
}
