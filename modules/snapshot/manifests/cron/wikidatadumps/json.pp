class snapshot::cron::wikidatadumps::json(
    $user   = undef,
) {
    include snapshot::cron::wikidatadumps::common

    $scriptPath = '/usr/local/bin/dumpwikidatajson.sh'
    file { $scriptPath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatajson.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    cron { 'wikidatajson-dump':
        ensure  => 'present',
        command => $scriptPath,
        user    => $user,
        minute  => '15',
        hour    => '3',
        weekday => '1',
        require => File[$scriptPath],
    }
}

