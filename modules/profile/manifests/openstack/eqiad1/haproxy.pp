class profile::openstack::eqiad1::haproxy(
    Stdlib::Fqdn $designate_host = lookup('profile::openstack::eqiad1::designate_host'),
    Stdlib::Fqdn $designate_host_standby = lookup('profile::openstack::eqiad1::designate_host_standby'),
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::eqiad1::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::eqiad1::nova_controller_standby'),
    Stdlib::Port $glance_api_bind_port = lookup('profile::openstack::eqiad1::glance::api_bind_port'),
    Stdlib::Port $glance_registry_bind_port = lookup('profile::openstack::eqiad1::glance::registry_bind_port'),
    Stdlib::Port $keystone_admin_bind_port = lookup('profile::openstack::eqiad1::keystone::admin_bind_port'),
    Stdlib::Port $keystone_public_bind_port = lookup('profile::openstack::eqiad1::keystone::public_bind_port'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::eqiad1::nova::metadata_listen_port'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::eqiad1::nova::osapi_compute_listen_port'),
    Stdlib::Port $placement_api_port = lookup('profile::openstack::eqiad1::nova::placement_api_port'),
) {

    profile::openstack::base::haproxy::site { 'designate':
        servers          => [$designate_host, $designate_host_standby],
        healthcheck_path => '/',
        port_frontend    => 9001,
        port_backend     => 9001,
    }

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

    # Unlike other nova services, the port used by the placement
    #  service is determined by the debian packaged init script.
    #  Rather than try to re-puppetize that file I'm
    #  just hard-coding the backend port (8778) here
    profile::openstack::base::haproxy::site { 'nova_placement':
        servers             => [$nova_controller, $nova_controller_standby],
        healthcheck_options => ['http-check expect status 401'],
        healthcheck_path    => '/',
        port_frontend       => 8778,
        port_backend        => $placement_api_port,
    }

    profile::openstack::base::haproxy::site { 'nova_metadata':
        servers          => [$nova_controller, $nova_controller_standby],
        healthcheck_path => '/',
        port_frontend    => 8775,
        port_backend     => $nova_metadata_listen_port,
    }
}
