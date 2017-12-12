# https://www.rabbitmq.com/
#
# User MAC's are not handled by Puppet
#
# Changing a user password
#  rabbitmqctl change_password <user> <password>
# Adding a user
#  rabbitmqctl add_user <user> <password>
#
# Creating user "<user>" ...
#  rabbitmqctl change_password <user> <password>
#  rabbitmqctl set_user_tags <user> administrator
# Setting tags for user "<user>" to [administrator] ...
#  rabbitmqctl set_permissions -p / <user> ".*" ".*" ".*"
#
# The management plugin may be desired
#  rabbitmq-plugins enable rabbitmq_management

class rabbitmq(
    $running = false,
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
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/rabbitmq/rabbitmqadmin',
        require => Package['rabbitmq-server'],
    }

    file { '/etc/rabbitmq/rabbitmq.config':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/rabbitmq/rabbitmq.config',
        require => Package['rabbitmq-server'],
    }

    service { 'rabbitmq-server':
        ensure  => $running,
        require => Package['rabbitmq-server'],
    }

    file { '/usr/local/sbin/drain_queue':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/rabbitmq/drain_queue',
    }
}
