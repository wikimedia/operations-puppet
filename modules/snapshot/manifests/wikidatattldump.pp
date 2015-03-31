class snapshot::wikidatattldump(
    $enable = true,
    $user   = undef,
) {
    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::wikidatattldump':
        ensure => $ensure,
        description => 'producer of weekly wikidata RDF/TTL dumps'
    }

    file { '/usr/local/bin/dumpwikidatattl.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/dumpwikidatattl.sh',
    }

    file { '/var/log/wikidatadump':
        mode    => '0755',
        ensure  => 'directory',
        owner   => 'datasets',
        group   => 'apache',
    }

    cron { 'wikidatattl-dump':
        ensure      => $ensure,
        command     => "/usr/local/bin/dumpwikidatattl.sh",
        user        => $user,
        minute      => '15',
        hour        => '3',
        weekday     => '1',
    }
}
