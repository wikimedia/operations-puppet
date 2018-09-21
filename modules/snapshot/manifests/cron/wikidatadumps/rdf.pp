class snapshot::cron::wikidatadumps::rdf(
    $user      = undef,
    $filesonly = false,
) {
    $scriptpath = '/usr/local/bin/dumpwikidatardf.sh'
    # serdi for translating ttl to nt
    require_package('serdi')
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpwikidatardf.sh',
        require => Class['snapshot::cron::wikidatadumps::common'],
    }

    if !$filesonly {
        cron { 'wikidatardf-dumps':
            ensure      => 'present',
            command     => "${scriptpath} all ttl nt; ${scriptpath} truthy nt; ${scriptpath} lexemes ttl nt",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '23',
            weekday     => '1',
            require     => File[$scriptpath],
        }
    }
}

