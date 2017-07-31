class rabbitmq::monitor(
    $rabbit_monitor_username,
    $rabbit_monitor_password,
    $rabbit_host='localhost:15672',
    ) {

    diamond::collector { 'RabbitMQ':
        settings => {
            'host'     => $rabbit_host,
            'user'     => $rabbit_monitor_username,
            'password' => $rabbit_monitor_password,
        },
        source   => 'puppet:///modules/rabbitmq/rabbitmq.py',
    }
}
