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

    file { '/etc/logrotate.d/dumpwikidatajson':
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/logrotate.d_dumpwikidatajson',
    }

    file { '/usr/local/bin/dumpwikidatajson.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/dumpwikidatajson.sh',
    }

    file { '/var/log/wikidatadump':
        mode    => '0755',
        ensure  => 'directory',
        owner   => 'datasets',
        group   => 'apache',
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
