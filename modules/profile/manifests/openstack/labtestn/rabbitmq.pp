class profile::openstack::labtestn::rabbitmq(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $monitor_user = hiera('profile::openstack::labtestn::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::labtestn::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::labtestn::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::labtestn::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::labtestn::labs_hosts_range'),
    $nova_api_host = hiera('profile::openstack::labtestn::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtestn::designate_host'),
){

    require ::profile::openstack::labtestn::cloudrepo
    class {'::profile::openstack::base::rabbitmq':
        nova_controller  => $nova_controller,
        monitor_user     => $monitor_user,
        monitor_password => $monitor_password,
        cleanup_password => $cleanup_password,
        file_handles     => $file_handles,
        labs_hosts_range => $labs_hosts_range,
        nova_api_host    => $nova_api_host,
        designate_host   => $designate_host,
    }
    contain '::profile::openstack::base::rabbitmq'
}
