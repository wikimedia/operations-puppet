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
    rabbitmq::user{'drainqueue':
        username      => $username,
        password      => $password,
        administrator => true,
    }

    if ($enabled) {
        $cron_ensure = 'present'
    }
    else {
        $cron_ensure = 'absent'
    }

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    cron { 'drain and log rabbit notifications.error queue':
            ensure  => $cron_ensure,
            user    => 'root',
            minute  => '35',
            command => "/usr/local/sbin/drain_queue notifications.error --password ${password} >> /var/log/rabbitmq/notifications_error.log 2>&1",
    }
}
