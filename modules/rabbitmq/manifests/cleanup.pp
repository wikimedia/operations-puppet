# Rabbit does a poor job of cleaning up queues
# that are not being consumed and this becomes costly
# over time.

# Enabled is only for active cron, all other
# components are setup if the class is included.

class rabbitmq::cleanup(
    $enabled=false,
    $username='drainqueue',
    $password,
    ) {

    require rabbitmq

    if ! ($password) {
       fail("password must be set for ${name}")
    }

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

    rabbitmq::user{'drainqueue':
        username => $username,
        password => $password,
    }

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    cron { 'drain and log rabbit notifications.error queue':
            ensure  => $ensure,
            user    => 'root',
            minute  => '35',
            command => "/usr/local/sbin/drain_queue notifications.error  --password ${password}>> /var/log/rabbitmq/notifications_error.log 2>&1",
    }
}
