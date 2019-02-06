class profile::openstack::main::nova::api::service(
    $version = hiera('profile::openstack::main::version'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $labs_hosts_range = hiera('profile::openstack::main::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::main::labs_hosts_range_v6')
    ) {

    require ::profile::openstack::main::nova::common
    class {'profile::openstack::base::nova::api::service':
        version             => $version,
        nova_api_host       => $nova_api_host,
        labs_hosts_range    => $labs_hosts_range,
        labs_hosts_range_v6 => $labs_hosts_range_v6,
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
