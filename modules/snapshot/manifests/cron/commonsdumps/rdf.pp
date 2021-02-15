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
        cron { 'commonsrdf-dumps':
            ensure      => 'present',
            command     => "${scriptpath} -p commons -d mediainfo -f ttl -e nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '19',
            weekday     => '0',
            require     => File[$scriptpath],
        }
    }
}

