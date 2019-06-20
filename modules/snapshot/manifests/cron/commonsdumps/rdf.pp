class snapshot::cron::commonsdumps::rdf(
    $user      = undef,
    $filesonly = false,
) {
    # functions for wikibase rdf dumps, with values specific to Commons
    file { '/usr/local/bin/commonsrdf_functions.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/commonsrdf_functions.sh',
    }

    $scriptpath = '/usr/local/bin/dumpwikibaserdf.sh'
    if !$filesonly {
        cron { 'wikidatardf-dumps':
            ensure      => 'present',
            command     => "${scriptpath} commons mediainfo ttl nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '15',
            weekday     => '0',
            require     => File[$scriptpath],
        }
    }
}

