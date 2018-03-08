class profile::openstack::main::rabbitmq(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $monitor_user = hiera('profile::openstack::main::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::main::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::main::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::main::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::main::labs_hosts_range'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $nova_user = hiera('profile::openstack::main::nova::rabbit_user'),
    $nova_password = hiera('profile::openstack::main::nova::rabbit_pass'),
){

    require ::profile::openstack::main::cloudrepo
    class {'::profile::openstack::base::rabbitmq':
        nova_controller  => $nova_controller,
        monitor_user     => $monitor_user,
        monitor_password => $monitor_password,
        cleanup_password => $cleanup_password,
        file_handles     => $file_handles,
        labs_hosts_range => $labs_hosts_range,
        nova_api_host    => $nova_api_host,
        designate_host   => $designate_host,
        nova_user        => $nova_user,
        nova_password    => $nova_password,
    }
}
