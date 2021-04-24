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
            ensure      => absent,
            command     => "${scriptpath} -p commons -d mediainfo -f ttl -e nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '19',
            weekday     => '0',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'commonsrdf-dump':
            ensure             => present,
            description        => 'Regular jobs to build rdf snapshot of commons structured data',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p commons -d mediainfo -f ttl -e nt",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sun *-*-* 19:0:0'},
            require            => File[$scriptpath],
        }
    }
}

