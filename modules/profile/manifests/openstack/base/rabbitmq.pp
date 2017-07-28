class profile::openstack::base::rabbitmq(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $monitor_user = hiera('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::base::rabbit_monitor_pass'),
    $file_handles = hiera('profile::openstack::base::rabbit_file_handles'),
){

    class { '::rabbitmq':
        running      => $::fqdn == $nova_controller,
        file_handles => $file_handles,
    }

    class { '::rabbitmq::monitor':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
}
