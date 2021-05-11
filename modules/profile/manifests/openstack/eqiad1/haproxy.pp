class profile::openstack::eqiad1::haproxy(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    Stdlib::Port $glance_api_bind_port = lookup('profile::openstack::eqiad1::glance::api_bind_port'),
    Stdlib::Port $placement_api_bind_port = lookup('profile::openstack::eqiad1::placement::api_bind_port'),
    Stdlib::Port $cinder_api_bind_port = lookup('profile::openstack::eqiad1::cinder::api_bind_port'),
    Stdlib::Port $trove_api_bind_port = lookup('profile::openstack::base::trove::api_bind_port'),
    Stdlib::Port $keystone_admin_bind_port = lookup('profile::openstack::eqiad1::keystone::admin_bind_port'),
    Stdlib::Port $keystone_public_bind_port = lookup('profile::openstack::eqiad1::keystone::public_bind_port'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::eqiad1::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::eqiad1::nova::metadata_listen_port'),
    Stdlib::Port $galera_listen_port = lookup('profile::openstack::eqiad1::galera::listen_port'),
    Stdlib::Fqdn $galera_primary_host = lookup('profile::openstack::eqiad1::galera::primary_host'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::eqiad1::nova::osapi_compute_listen_port'),
) {

    profile::openstack::base::haproxy::site { 'designate':
        servers            => $designate_hosts,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_frontend      => 9001,
        port_backend       => 9001,
    }

    profile::openstack::base::haproxy::site { 'keystone_admin':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 35357,
        port_backend       => $keystone_admin_bind_port,
    }

    profile::openstack::base::haproxy::site { 'keystone_public':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 5000,
        port_backend       => $keystone_public_bind_port,
    }

    profile::openstack::base::haproxy::site { 'glance_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 9292,
        port_backend       => $glance_api_bind_port,
    }

    profile::openstack::base::haproxy::site { 'cinder_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 8776,
        port_backend       => $cinder_api_bind_port,
    }

    profile::openstack::base::haproxy::site { 'trove_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 8779,
        port_backend       => $trove_api_bind_port,
    }

    profile::openstack::base::haproxy::site { 'neutron':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 9696,
        port_backend       => $neutron_bind_port,
    }

    profile::openstack::base::haproxy::site { 'nova_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_frontend      => 8774,
        port_backend       => $nova_osapi_compute_listen_port,
    }

    profile::openstack::base::haproxy::site { 'placement_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_frontend      => 8778,
        port_backend       => $placement_api_bind_port,
    }

    profile::openstack::base::haproxy::site { 'nova_metadata':
        servers            => $openstack_controllers,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_frontend      => 8775,
        port_backend       => $nova_metadata_listen_port,
    }

    profile::openstack::base::haproxy::site { 'mysql':
        servers             => $openstack_controllers,
        port_frontend       => 3306,
        port_backend        => $galera_listen_port,
        primary_host        => $galera_primary_host,
        healthcheck_options => ['option httpchk'],
        type                => 'tcp'
    }
}
