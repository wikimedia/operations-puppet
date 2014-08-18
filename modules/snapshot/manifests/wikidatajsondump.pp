class snapshot::wikidatajsondump(
    $enable = true,
    $user   = undef,
) {
    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::wikidatajsondump':
        ensure => $ensure,
        description => 'producer of weekly wikidata json dumps'
    }

    file { '/usr/local/bin/dumpwikidatajson.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/dumpwikidatajson.sh',
    }

    cron { 'wikidatajson-dump':
        ensure      => $ensure,
        command     => "/usr/local/bin/dumpwikidatajson.sh",
        user        => $user,
        minute      => '15',
        hour        => '3',
        weekday     => '1',
    }
}
