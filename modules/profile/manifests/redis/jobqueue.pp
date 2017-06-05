# Very simple profile for redis for the MW jobqueue. It works as an addition to
# profile::redis::multidc
# This is basically to cope with issues described in
# https://phabricator.wikimedia.org/T163337 with a ugly workaround: restart
# periodically the redis slaves in order to force a
# service restart
class profile::redis::jobqueue {
    require ::profile::redis::multidc
    file { '/usr/local/bin/restart-redis-if-slave':
        ensure => present,
        source => 'puppet:///modules/profile/redis/restart-redis-if-slave.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    cron { 'jobqueue-redis-conditional-restart':
        command => "/usr/local/bin/restart-redis-if-slave ${::profile::redis::multidc::instances}",
        hour    => 1,
        minute  => 0,
    }
}
