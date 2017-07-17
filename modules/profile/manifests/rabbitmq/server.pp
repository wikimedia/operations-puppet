class profile::rabbitmq::server(
    $monitor_user = hiera('profile::rabbitmq::monitor::user'),
    $monitor_password = hiera('profile::rabbitmq::monitor::password'),
    $file_handles = hiera('profile::rabbitmq::file_handles'),
){

    class { 'rabbitmq':
        file_handles => $file_handles,
    }

    class { 'rabbitmq::monitor':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
}
