class profile::openstack::main::rabbitmq(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $monitor_user = hiera('profile::openstack::main::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::main::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::main::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::main::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::main::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::main::labs_hosts_range_v6'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $designate_host_standby = hiera('profile::openstack::main::designate_host_standby'),
    $nova_rabbit_password = hiera('profile::openstack::main::nova::rabbit_pass'),
){
    class {'::profile::openstack::base::rabbitmq':
        nova_controller        => $nova_controller,
        monitor_user           => $monitor_user,
        monitor_password       => $monitor_password,
        cleanup_password       => $cleanup_password,
        file_handles           => $file_handles,
        labs_hosts_range       => $labs_hosts_range,
        labs_hosts_range_v6    => $labs_hosts_range_v6,
        nova_api_host          => $nova_api_host,
        designate_host         => $designate_host,
        designate_host_standby => $designate_host_standby,
        nova_rabbit_password   => $nova_rabbit_password,
    }
}
