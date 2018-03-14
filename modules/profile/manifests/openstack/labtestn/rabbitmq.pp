class profile::openstack::labtestn::rabbitmq(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $monitor_user = hiera('profile::openstack::labtestn::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::labtestn::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::labtestn::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::labtestn::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::labtestn::labs_hosts_range'),
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtestn::designate_host'),
    $nova_rabbit_password = hiera('profile::openstack::labtestn::nova::rabbit_pass'),
    $neutron_rabbit_user = hiera('profile::openstack::base::neutron::rabbit_user'),
    $neutron_rabbit_password = hiera('profile::openstack::labtestn::neutron::rabbit_pass'),
){

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::rabbitmq':
        nova_controller      => $nova_controller,
        monitor_user         => $monitor_user,
        monitor_password     => $monitor_password,
        cleanup_password     => $cleanup_password,
        file_handles         => $file_handles,
        labs_hosts_range     => $labs_hosts_range,
        nova_api_host        => $nova_api_host,
        designate_host       => $designate_host,
        nova_rabbit_password => $nova_rabbit_password,
    }
    contain '::profile::openstack::base::rabbitmq'

    # move to base when appropriate along with lookups above
    class {'::openstack::neutron::rabbit':
        username => $neutron_rabbit_user,
        password => $neutron_rabbit_password,
    }
    contain '::openstack::neutron::rabbit'
}
