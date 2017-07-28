class profile::openstack::base::rabbitmq(
    $monitor_user = hiera('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::base::rabbit_monitor_pass'),
    $file_handles = hiera('profile::openstack::base::rabbit_file_handles'),
){

    class { '::rabbitmq':
        file_handles => $file_handles,
    }

    class { '::rabbitmq::monitor':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
}
