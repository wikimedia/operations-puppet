class snapshot::cron::wikidatadumps::json(
    $user      = undef,
    $filesonly = false,
) {
    # functions for wikibase json dumps, with values specific to Wikidata
    file { '/usr/local/bin/wikidatajson_functions.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/wikidatajson_functions.sh',
    }

    $scriptpath = '/usr/local/bin/dumpwikibasejson.sh'
    if !$filesonly {
        # project: wikidata, dump type: all, entities to be dumped (default): item|property
        systemd::timer::job { 'wikidatajson-dump':
            ensure             => present,
            description        => 'Regular jobs to build json snapshot of wikidata',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p wikidata -d all",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 3:15:0'},
            require            => File[$scriptpath],
        }
        # project: wikidata, dump type: lexemes, entity to be dumped: lexeme
        systemd::timer::job { 'wikidatajson-lexemes-dump':
            ensure             => present,
            description        => 'Regular jobs to build json snapshot of wikidata lexemes',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p wikidata -d lexemes -e lexeme",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Wed *-*-* 3:15:0'},
            require            => File[$scriptpath],
        }
    }
}

