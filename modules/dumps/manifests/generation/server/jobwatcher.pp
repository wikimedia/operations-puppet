class dumps::generation::server::jobwatcher(
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

    cron { 'dumps-jobs-watcher':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/bin/bash /usr/local/bin/job_watcher.sh --dumpsbasedir ${dumpsbasedir} --locksbasedir ${locksbasedir}",
        user        => $user,
        minute      => '10',
        hour        => '*/8',
        require     => File['/usr/local/bin/job_watcher.sh'],
    }
}
