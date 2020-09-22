class snapshot::cron::commonsdumps::json(
    $user      = undef,
    $filesonly = false,
) {
    # functions for wikibase json dumps, with values specific to Commons
    file { '/usr/local/bin/commonsjson_functions.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/commonsjson_functions.sh',
    }

    $scriptpath = '/usr/local/bin/dumpwikibasejson.sh'
    if !$filesonly {
        # project: commons, dump type: all, entities to be dumped: mediainfo
        # extra args: ignore-missing
        cron { 'commonsjson-dump':
            ensure      => 'present',
            command     => "${scriptpath} -p commons -d all -e mediainfo -E --ignore-missing",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '15',
            hour        => '3',
            weekday     => '1',
            require     => File[$scriptpath],
        }
    }
}

