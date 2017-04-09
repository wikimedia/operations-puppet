class snapshot::cron::wikidatadumps::ttl(
    $user   = undef,
) {
    include ::snapshot::cron::wikidatadumps::common

    $scriptpath = '/usr/local/bin/dumpwikidatattl.sh'
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatattl.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    # Temp: Remove old hook
    cron { 'wikidatattl-dump':
        ensure  => 'absent',
    }

    cron { 'wikidatattl-dump-all':
        ensure  => 'present',
        command => "{$scriptpath} all",
        user    => $user,
        minute  => '0',
        hour    => '23',
        weekday => '1',
        require => File[$scriptpath],
    }
}

