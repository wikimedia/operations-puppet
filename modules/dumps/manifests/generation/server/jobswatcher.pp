class dumps::generation::server::jobswatcher(
    $dumpsbasedir = undef,
    $locksbasedir = undef,
    $user         = undef,
)  {
    file { '/usr/local/bin/job_watcher.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/job_watcher.sh',
    }

    systemd::timer::job { 'dump-jobs-watcher':
        ensure      => 'present',
        description => 'Watch for stalled XML dumps',
        environment => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command     => "/bin/bash /usr/local/bin/job_watcher.sh --dumpsbasedir ${dumpsbasedir} --locksbasedir ${locksbasedir}",
        user        => $user,
        interval    => {'start' => 'OnCalendar', 'interval' => '00/8:10'}
    }

    cron { 'dumps-jobs-watcher':
        ensure => 'absent',
        user   => $user,
    }
}
