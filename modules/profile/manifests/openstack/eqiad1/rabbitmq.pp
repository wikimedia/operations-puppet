class profile::openstack::eqiad1::rabbitmq(
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $monitor_user = hiera('profile::openstack::eqiad1::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::eqiad1::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::eqiad1::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::eqiad1::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    $nova_api_host = hiera('profile::openstack::eqiad1::nova_api_host'),
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $nova_rabbit_password = hiera('profile::openstack::eqiad1::nova::rabbit_pass'),
    $neutron_rabbit_user = hiera('profile::openstack::base::neutron::rabbit_user'),
    $neutron_rabbit_password = hiera('profile::openstack::eqiad1::neutron::rabbit_pass'),
){

    require ::profile::openstack::eqiad1::clientlib
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
