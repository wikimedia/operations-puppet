class snapshot::cron::wikidatadumps::rdf(
    $user      = undef,
    $filesonly = false,
) {
    # functions for wikibase rdf dumps, with values specific to wikidata
    file { '/usr/local/bin/wikidatardf_functions.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/wikidatardf_functions.sh',
    }

    $scriptpath = '/usr/local/bin/dumpwikibaserdf.sh'
    if !$filesonly {
        cron { 'wikidatardf-dumps':
            ensure      => 'present',
            command     => "${scriptpath} wikidata all ttl nt; ${scriptpath} wikidata truthy nt; ${scriptpath} wikidata lexemes ttl nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '23',
            weekday     => '1',
            require     => File[$scriptpath],
        }
    }
}

