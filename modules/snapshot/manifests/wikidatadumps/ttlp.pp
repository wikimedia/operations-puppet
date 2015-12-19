class snapshot::wikidatadumps::ttl(
    $enable = true,
    $user   = undef,
) {
    include snapshot::wikidatadumps::common

    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::wikidatadumps::ttl':
        ensure      => $ensure,
        description => 'producer of weekly wikidata ttl dumps'
    }

    $scriptPath = '/usr/local/bin/dumpwikidatattl.sh'
    file { $scriptPath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/dumpwikidatattl.sh',
        require => Class['snapshot::wikidatadumps::common'],
    }

    cron { 'wikidatattl-dump':
        ensure  => $ensure,
        command => $scriptPath,
        user    => $user,
        minute  => '0',
        hour    => '23',
        weekday => '1',
        require => File[$scriptPath],
    }
}

