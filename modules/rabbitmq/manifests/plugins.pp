class rabbitmq::plugins {

    include rabbitmq
    # https://www.rabbitmq.com/management.html
    # Needed for https://www.rabbitmq.com/management-cli.html
    # rabbitmq-plugins -E list | egrep '\[E\*]\srabbitmq_management
    exec { 'enable_management_plugin':
        environment => 'HOME=/var/lib/rabbitmq/',
        command     => '/usr/sbin/rabbitmq-plugins enable rabbitmq_management',
        unless      => '/usr/sbin/rabbitmq-plugins -E list | grep rabbitmq_management',
        logoutput   => true,
        notify      => Service['rabbitmq-server'],
    }
}
