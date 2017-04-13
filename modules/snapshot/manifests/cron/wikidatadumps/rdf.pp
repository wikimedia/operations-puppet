class snapshot::cron::wikidatadumps::rdf(
    $user   = undef,
) {
    include ::snapshot::cron::wikidatadumps::common

    $scriptpath = '/usr/local/bin/dumpwikidatardf.sh'
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatardf.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    cron { 'wikidatattl-dump-all':
        ensure  => 'present',
        command => "${scriptpath} all ttl",
        user    => $user,
        minute  => '0',
        hour    => '23',
        weekday => '1',
        require => File[$scriptpath],
    }

    cron { 'wikidatant-dump-truthy':
        ensure  => 'present',
        command => "${scriptpath} truthy nt",
        user    => $user,
        minute  => '0',
        hour    => '17',
        weekday => '1',
        require => File[$scriptpath],
    }
}

