
# = Class: profile::quarry:querykiller
#
# Sets up a cron based query-killer
class profile::quarry::querykiller {
    require ::profile::quarry::base

    file { '/var/log/quarry':
        ensure => directory,
        owner  => 'quarry',
        group  => 'quarry',
    }

    cron { 'query-killer':
        command => "${quarry::base::clone_path}/quarry/web/killer.py",
        minute  => '*',
        user    => 'quarry',
    }
}
