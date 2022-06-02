# SPDX-License-Identifier: Apache-2.0
# Rabbit does a poor job of cleaning up queues
# that are not being consumed and this becomes costly
# over time.

# Enabled is only for active cron, all other
# components are setup if the class is included.

class rabbitmq::cleanup(
    $password,
    $enabled=false,
    $username='drainqueue',
    ) {

    require rabbitmq

    if ! ($password) {
        fail("password must be set for ${name}")
    }

    file { '/usr/local/sbin/drain_queue':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/rabbitmq/drain_queue.py',
    }

    # admin is needed for queue cleanup
    rabbitmq::user{ $username:
        password      => $password,
        administrator => true,
    }

    if ($enabled) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    systemd::timer::job { 'drain_rabbitmq_notification_error':
        ensure          => $ensure,
        description     => 'Drain and log RabbitMQ notifications.error queue',
        user            => 'root',
        command         => "/usr/local/sbin/drain_queue notifications.error --password ${password}",
        logfile_basedir => '/var/log/rabbitmq/',
        logfile_name    => 'notifications_error.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*:0/35:00'}
    }

    cron { 'drain and log rabbit notifications.error queue':
            ensure => 'absent',
            user   => 'root',
    }
}
