# Very simple profile for redis for the MW jobqueue local slaves. It works as an
# addition to profile::redis::slave
# This is basically to cope with issues described in
# https://phabricator.wikimedia.org/T163337 with a ugly workaround: restart
# periodically the redis slaves in order to force a
# service restart
class profile::redis::jobqueue_slave {
    require ::profile::redis::slave
    file { '/usr/local/bin/restart-redis-if-slave':
        ensure => absent,
    }
    cron { 'jobqueue-redis-conditional-restart':
        ensure => absent
    }
}
