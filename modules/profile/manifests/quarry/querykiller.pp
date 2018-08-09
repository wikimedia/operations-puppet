
# = Class: profile::quarry:querykiller
#
# Sets up a cron based query-killer
class profile::quarry::querykiller(
    $clone_path = hiera('profile::quarry::base::clone_path'),
    $venv_path = hiera('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    file { '/var/log/quarry':
        ensure => directory,
        owner  => 'quarry',
        group  => 'quarry',
    }

    cron { 'query-killer':
        command => "${venv_path}/bin/python ${clone_path}/quarry/web/killer.py",
        minute  => '*',
        user    => 'quarry',
    }
}
