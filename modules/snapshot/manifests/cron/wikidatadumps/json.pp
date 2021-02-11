class snapshot::cron::wikidatadumps::json(
    $user      = undef,
    $filesonly = false,
) {
    $scriptpath = '/usr/local/bin/dumpwikidatajson.sh'
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatajson.sh',
        require => Class['snapshot::cron::wikibase'],
    }

    if !$filesonly {
        # project: wikidata, dump type: all, entities to be dumped (default): item|property
        cron { 'wikidatajson-dump':
            ensure      => 'present',
            command     => "${scriptpath} -p wikidata -d all",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '15',
            hour        => '3',
            weekday     => '1',
            require     => File[$scriptpath],
        }
        # project: wikidata, dump type: lexemes, entity to be dumped: lexeme
        cron { 'wikidatajson-lexemes-dump':
            ensure      => 'present',
            command     => "${scriptpath} -p wikidata -d lexemes -e lexeme",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '15',
            hour        => '3',
            weekday     => '3',
            require     => File[$scriptpath],
        }
    }
}

