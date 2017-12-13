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

    file { '/etc/prometheus/rabbitmq-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('profile/prometheus/rabbitmq-exporter.conf.erb'),
    }
}
