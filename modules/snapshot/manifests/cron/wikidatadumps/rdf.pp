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
        cron { 'wikidatardf-all-dumps':
            ensure      => absent,
            command     => "${scriptpath} -p wikidata -d all -f ttl -e nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '23',
            weekday     => '1',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'wikidatardf-all-dumps':
            ensure             => present,
            description        => 'Regular jobs to build rdf snapshot of wikidata',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p wikidata -d all -f ttl -e nt",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 23:0:0'},
            require            => File[$scriptpath],
        }
        cron { 'wikidatardf-truthy-dumps':
            ensure      => absent,
            command     => "${scriptpath} -p wikidata -d truthy -f nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '23',
            weekday     => '3',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'wikidatardf-truthy-dumps':
            ensure             => present,
            description        => 'Regular jobs to build rdf snapshot of wikidata truthy statements',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p wikidata -d truthy -f nt",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Wed *-*-* 23:0:0'},
            require            => File[$scriptpath],
        }
        cron { 'wikidatardf-lexemes-dumps':
            ensure      => absent,
            command     => "${scriptpath} -p wikidata -d lexemes -f ttl -e nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '23',
            weekday     => '5',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'wikidatardf-lexemes-dumps':
            ensure             => present,
            description        => 'Regular jobs to build rdf snapshot of wikidata lexemes',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} -p wikidata -d lexemes -f ttl -e nt",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Fri *-*-* 23:0:0'},
            require            => File[$scriptpath],
        }
    }
}

