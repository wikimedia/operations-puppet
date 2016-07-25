class snapshot::cron::wikidatadumps::ttl(
    $user   = undef,
) {
    include snapshot::cron::wikidatadumps::common

    $scriptPath = '/usr/local/bin/dumpwikidatattl.sh'
    file { $scriptPath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatattl.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    cron { 'wikidatattl-dump':
        ensure  => 'present',
        command => $scriptPath,
        user    => $user,
        minute  => '0',
        hour    => '23',
        weekday => '1',
        require => File[$scriptPath],
    }
}

