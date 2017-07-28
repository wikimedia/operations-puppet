class profile::openstack::labtestn::rabbitmq(
    $monitor_user = hiera('profile::openstack::labtestn::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::labtestn::rabbit_monitor_pass'),
    $file_handles = hiera('profile::openstack::labtestn::rabbit_file_handles'),
){
    require ::profile::openstack::labtestn::cloudrepo

    class {'::profile::openstack::base::rabbitmq':
        monitor_user     => $monitor_user,
        monitor_password => $monitor_password,
        file_handles     => $file_handles,
    }
}
