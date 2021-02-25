
# = Class: profile::quarry:querykiller
#
# Sets up a regular query-killer
class profile::quarry::querykiller(
    Stdlib::Unixpath $clone_path = lookup('profile::quarry::base::clone_path'),
    Stdlib::Unixpath $venv_path  = lookup('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    file { '/var/log/quarry':
        ensure => directory,
        owner  => 'quarry',
        group  => 'quarry',
    }

    systemd::timer::job { 'query-killer':
        ensure      => present,
        user        => 'quarry',
        description => 'Kill slow queries',
        command     => "${venv_path}/bin/python ${clone_path}/quarry/web/killer.py",
        interval    => {'start'    => 'OnCalendar', 'interval' => '*-*-* *:*:00'},
    }
}
