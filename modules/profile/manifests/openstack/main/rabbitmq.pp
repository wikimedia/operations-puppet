class profile::openstack::main::rabbitmq(
    $monitor_user = hiera('profile::openstack::main::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::main::rabbit_monitor_pass'),
    $file_handles = hiera('profile::openstack::main::rabbit_file_handles'),
){
    require ::profile::openstack::labtestn::cloudrepo

    class {'::profile::openstack::base::rabbitmq':
        monitor_user     => $monitor_user,
        monitor_password => $monitor_password,
        file_handles     => $file_handles,
    }
}
