class rabbitmq::plugins {

    require rabbitmq

    # this appears to be idempotent
    # https://www.rabbitmq.com/management.html
    # Needed for https://www.rabbitmq.com/management-cli.html
    # rabbitmq-plugins -E list | egrep '\[E\*]\srabbitmq_management
    exec { 'enable_management_plugin':
        command   => '/usr/sbin/rabbitmq-plugins enable rabbitmq_management',
        unless    => '/usr/sbin/rabbitmq-plugins -E list | egrep "\[E\*]\srabbitmq_management"'
        logoutput => true,
    }
}
