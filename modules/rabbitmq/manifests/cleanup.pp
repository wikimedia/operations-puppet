# Rabbit does a poor job of cleaning up queues
# that are not being consumed and this becomes costly
# over time.

class rabbitmq::cleanup(
    $enabled=false,
    ) {

    require rabbitmq

    if ($enabled) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    cron { 'drain and log rabbit notifications.error queue':
            ensure  => $ensure,
            user    => 'root',
            minute  => '35',
            command => '/usr/local/sbin/drain_queue notifications.error >> /var/log/rabbitmq/notifications_error.log 2>&1',
    }
}
