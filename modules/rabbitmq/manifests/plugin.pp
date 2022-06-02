# SPDX-License-Identifier: Apache-2.0
# Enables the specified RabbitMQ plugin
define rabbitmq::plugin () {
    exec { "rabbitmq-enable-plugin-${title}":
        environment => 'HOME=/var/lib/rabbitmq/',
        command     => "/usr/sbin/rabbitmq-plugins enable ${title}",
        unless      => "/usr/sbin/rabbitmq-plugins list -E | grep ${title}",
        logoutput   => true,
        require     => Service['rabbitmq-server'],
    }
}
