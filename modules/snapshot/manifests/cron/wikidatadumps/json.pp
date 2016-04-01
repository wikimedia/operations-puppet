class snapshot::cron::wikidatadumps::json(
    $enable = true,
    $user   = undef,
) {
    include snapshot::cron::wikidatadumps::common

    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $scriptPath = '/usr/local/bin/dumpwikidatajson.sh'
    file { $scriptPath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/dumpwikidatajson.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    cron { 'wikidatajson-dump':
        ensure  => $ensure,
        command => $scriptPath,
        user    => $user,
        minute  => '15',
        hour    => '3',
        weekday => '1',
        require => File[$scriptPath],
    }
}

