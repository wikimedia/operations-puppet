class snapshot::cron::wikidatadumps::json(
    $user   = undef,
) {
    $scriptpath = '/usr/local/bin/dumpwikidatajson.sh'
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatajson.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    cron { 'wikidatajson-dump':
        ensure      => 'present',
        command     => $scriptpath,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '3',
        weekday     => '1',
        require     => File[$scriptpath],
    }
}

