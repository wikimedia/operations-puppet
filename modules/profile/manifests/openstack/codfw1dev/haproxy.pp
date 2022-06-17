class profile::openstack::codfw1dev::haproxy(
    Optional[String] $acme_chief_cert_name = lookup('profile::openstack::codfw1dev::haproxy::acme_chief_cert_name', {default_value => undef}),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Stdlib::Port $glance_api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    Stdlib::Port $placement_api_bind_port = lookup('profile::openstack::codfw1dev::placement::api_bind_port'),
    Stdlib::Port $cinder_api_bind_port = lookup('profile::openstack::codfw1dev::cinder::api_bind_port'),
    Stdlib::Port $trove_api_bind_port = lookup('profile::openstack::base::trove::api_bind_port'),
    Stdlib::Port $radosgw_api_bind_port = lookup('profile::openstack::base::radosgw::api_bind_port'),
    Stdlib::Port $barbican_bind_port = lookup('profile::openstack::codfw1dev::barbican::bind_port'),
    Stdlib::Port $heat_bind_port = lookup('profile::openstack::codfw1dev::heat::api_bind_port'),
    Stdlib::Port $magnum_bind_port = lookup('profile::openstack::codfw1dev::magnum::api_bind_port'),
    Stdlib::Port $cloudformation_bind_port = lookup('profile::openstack::codfw1dev::heat::cfn_api_bind_port'),
    Stdlib::Port $keystone_admin_bind_port = lookup('profile::openstack::codfw1dev::keystone::admin_bind_port'),
    Stdlib::Port $keystone_public_bind_port = lookup('profile::openstack::codfw1dev::keystone::public_bind_port'),
    Stdlib::Port $neutron_bind_port = lookup('profile::openstack::codfw1dev::neutron::bind_port'),
    Stdlib::Port $nova_metadata_listen_port = lookup('profile::openstack::codfw1dev::nova::metadata_listen_port'),
    Stdlib::Port $galera_listen_port = lookup('profile::openstack::codfw1dev::galera::listen_port'),
    Stdlib::Fqdn $galera_primary_host = lookup('profile::openstack::codfw1dev::galera::primary_host'),
    Stdlib::Port $nova_osapi_compute_listen_port = lookup('profile::openstack::codfw1dev::nova::osapi_compute_listen_port'),
) {
    if $acme_chief_cert_name != undef {
        acme_chief::cert { $acme_chief_cert_name:
            puppet_svc => 'haproxy',
        }
    }

    include profile::openstack::base::haproxy

    openstack::haproxy::site { 'designate':
        servers            => $designate_hosts,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_backend       => 9001,
        frontends          => [
            {
                port => 9001,
            },
            {
                port                 => 29001,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    # Note that because keystone admin uses a weird, extremely-high-number
    #  port by default, we need to use a non-standard port for its
    #  tls port as well: 25357 rather than the more expected 225357
    openstack::haproxy::site { 'keystone_admin':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $keystone_admin_bind_port,
        frontends          => [
            {
                port => 35357,
            },
            {
                port                 => 25357,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'keystone_public':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $keystone_public_bind_port,
        frontends          => [
            {
                port => 5000,
            },
            {
                port                 => 25000,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'glance_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $glance_api_bind_port,
        frontends          => [
            {
                port => 9292,
            },
            {
                port                 => 29292,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'cinder_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $cinder_api_bind_port,
        frontends          => [
            {
                port => 8776,
            },
            {
                port                 => 28776,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'trove_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $trove_api_bind_port,
        frontends          => [
            {
                port => 8779,
            },
            {
                port                 => 28779,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'radosgw_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $radosgw_api_bind_port,
        frontends          => [
            {
                port => 8080,
            },
            {
                port                 => 28080,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'barbican':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $barbican_bind_port,
        frontends          => [
            {
                port => 9311,
            },
            {
                port                 => 29311,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'heat':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $heat_bind_port,
        frontends          => [
            {
                port => 8004,
            },
            {
                port                 => 28004,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'magnum':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $magnum_bind_port,
        frontends          => [
            {
                port => 9511,
            },
            {
                port                 => 29511,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'cloudformation':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $cloudformation_bind_port,
        frontends          => [
            {
                port => 8000,
            },
            {
                port                 => 28000,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'neutron':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $neutron_bind_port,
        frontends          => [
            {
                port => 9696,
            },
            {
                port                 => 29696,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'nova_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_backend       => $nova_osapi_compute_listen_port,
        frontends          => [
            {
                port => 8774,
            },
            {
                port                 => 28774,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'placement_api':
        servers            => $openstack_controllers,
        healthcheck_method => 'GET',
        healthcheck_path   => '/',
        port_backend       => $placement_api_bind_port,
        frontends          => [
            {
                port => 8778,
            },
            {
                port                 => 28778,
                acme_chief_cert_name => $acme_chief_cert_name,
            },
        ],
    }

    openstack::haproxy::site { 'nova_metadata':
        servers            => $openstack_controllers,
        healthcheck_method => 'HEAD',
        healthcheck_path   => '/',
        port_backend       => $nova_metadata_listen_port,
        frontends          => [
            {
                port => 8775,
            },
        ],
    }

    openstack::haproxy::site { 'mysql':
        servers             => $openstack_controllers,
        port_backend        => $galera_listen_port,
        primary_host        => $galera_primary_host,
        healthcheck_options => [
            'option httpchk',
            'http-check connect',
            'http-check send meth GET uri /',
            'http-check expect status 200',
        ],
        type                => 'tcp',
        frontends           => [
            {
                port => 3306,
            },
        ],
    }
}
