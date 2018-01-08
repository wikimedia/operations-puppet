# https://www.rabbitmq.com/
#
# User MAC's are not handled by Puppet
#
# Adding a user
#  rabbitmqctl add_user <user> <password>
# Changing a user password
#  rabbitmqctl change_password <user> <password>
#
# Setting tags for user "<user>" to [administrator] ...
#  rabbitmqctl set_user_tags <user> administrator
# All permissions example
#  rabbitmqctl set_permissions -p / <user> ".*" ".*" ".*"
#
# The management plugin may be desired
#  rabbitmq-plugins enable rabbitmq_management

class rabbitmq(
    $running = true,
    $file_handles = '1024',
    ) {

    package { [ 'rabbitmq-server' ]:
        ensure  => 'present',
    }

    file { '/etc/default/rabbitmq-server':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('rabbitmq/rabbitmq-server.default.erb'),
        require => Package['rabbitmq-server'],
        notify  => Service['rabbitmq-server'],
    }

    file { '/usr/local/sbin/rabbitmqadmin':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        source  => 'puppet:///modules/rabbitmq/rabbitmqadmin',
        require => Package['rabbitmq-server'],
    }

    file { '/etc/rabbitmq/rabbitmq.config':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/rabbitmq/rabbitmq.config',
        require => Package['rabbitmq-server'],
    }

    file {'/usr/local/sbin/rabbit_random_guest':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        source  => 'puppet:///modules/rabbitmq/random_guesh.sh',
        require => Package['rabbitmq-server'],
    }

    exec { 'invalidate_rabbitmq_guest_account':
        command     => 'rabbit_random_guest',
        path        => ['/usr/local/sbin/'],
        subscribe   => File['/usr/local/sbin/random_guest'],
        refreshonly => true,
    }

    # this appears to be idempotent
    # https://www.rabbitmq.com/management.html
    # Needed for https://www.rabbitmq.com/management-cli.html
    # rabbitmq-plugins -E list | egrep '\[E\*]\srabbitmq_management
    exec { 'enable_management_plugin':
        command     => 'rabbitmq-plugins enable rabbitmq_management',
        path        => ['/usr/sbin/'],
        subscribe   => Package['rabbitmq-server'],
        refreshonly => true,
    }

    service { 'rabbitmq-server':
        ensure  => $running,
        require => Package['rabbitmq-server'],
    }
}
