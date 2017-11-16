# Very simple profile for redis for the MW jobqueue local slaves. It works as an
# addition to profile::redis::slave
# This is basically to cope with issues described in
# https://phabricator.wikimedia.org/T163337 with a ugly workaround: restart
# periodically the redis slaves in order to force a
# service restart
class profile::redis::jobqueue_slave {
    require ::profile::redis::slave
    file { '/usr/local/bin/restart-redis-if-slave':
        ensure => present,
        source => 'puppet:///modules/profile/redis/restart-redis-if-slave.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
    $instance_str = join($::profile::redis::slave::instances, ' ')

    $restart_hour  = $::site ? {
        'codfw'   => 2,
        'default' => 1,
    }

    cron { 'jobqueue-redis-conditional-restart':
        command => "/usr/local/bin/restart-redis-if-slave ${instance_str}",
        hour    => $restart_hour,
        minute  => 0,
    }
}
