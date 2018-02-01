class profile::openstack::labtest::rabbitmq(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $monitor_user = hiera('profile::openstack::labtest::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::labtest::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::labtest::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::labtest::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::labtest::labs_hosts_range'),
    $nova_api_host = hiera('profile::openstack::labtest::nova_api_host'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
){

    require ::profile::openstack::labtest::cloudrepo
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
