class dumps::otherdumps::wikidata(
    $user = undef,
    $confsdir = undef,
    $repodir = undef,
    $otherdumpsdir = undef,
) {
    class {'::dumps::otherdumps::wikidata::common':
        user => $user,
    }
    class {'::dumps::otherdumps::wikidata::json':
        user => $user,
    }
    class {'::dumps::otherdumps::wikidata::rdf':
        user => $user,
    }

    file { '/usr/local/bin/wikidata-weeklies.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/wikidata-weeklies.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumps/otherdumps/wikidata-weeklies.sh',
        require => Class[':dumps::otherdumps::wikidata::common',
                         '::dumps::otherdumps::wikidata::json',
                         '::dumps::otherdumps::wikidata::rdf'],
    }

    cron { 'otherdumps-weeklies':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/wikidata-weeklies.sh --confsdir $confsdir --repodir $repodir --otherdumpsdir $otherdumpsdir",
        minute      => '10',
        hour        => '6',
        weekday     => '0',
        require     => File['/usr/local/bin/wikidata-weeklies.sh'],
    }

}
