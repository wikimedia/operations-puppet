class profile::openstack::main::nova::api::service(
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    ) {

    require ::profile::openstack::main::nova::common
    class {'profile::openstack::base::nova::api::service':
        nova_api_host => $nova_api_host,
    }

    class {'::openstack::nova::api::monitor':
        active         => ($::fqdn == $nova_api_host),
        critical       => true,
        contact_groups => 'wmcs-team',
    }
    contain '::openstack::nova::api::monitor'

    class {'::openstack::nova::log_fixes':}
    contain '::openstack::nova::log_fixes'
}
