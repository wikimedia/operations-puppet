# Rabbit does a poor job of cleaning up queues
# that are not being consumed and this becomes costly
# over time.

class rabbitmq::cleanup(
    $enabled=false,
    ) {

    if ($enabled) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/sbin/drain_queue':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/rabbitmq/drain_queue',
    }

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    cron {
        'drain and log rabbit notifications.error queue':
            ensure  => $ensure,
            user    => 'root',
            minute  => '35',
            command => '/usr/local/sbin/drain_queue notifications.error >> /var/log/rabbitmq/notifications_error.l$
    }
}
