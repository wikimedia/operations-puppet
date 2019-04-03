class profile::openstack::labtest::rabbitmq(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $monitor_user = hiera('profile::openstack::labtest::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::labtest::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::labtest::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::labtest::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::labtest::labs_hosts_range_v6'),
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $designate_host_standby = hiera('profile::openstack::labtest::designate_host_standby'),
    $nova_rabbit_password = hiera('profile::openstack::labtest::nova::rabbit_pass'),
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
    contain '::profile::openstack::base::rabbitmq'
}
