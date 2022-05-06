class dumps::generation::server::statsender(
    $dumpsbasedir   = undef,
    $sender_address = undef,
    $user           = undef,
)  {
    ensure_packages('s-nail')

    file { '/usr/local/bin/get_dump_stats.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/get_dump_stats.sh',
    }

    systemd::timer::job { 'dumps-stats-sender':
        ensure      => 'present',
        description => 'Collect monthly statistics for XML dumps',
        environment => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command     => "/bin/bash /usr/local/bin/get_dump_stats.sh --dumpsbasedir ${dumpsbasedir} --sender_address ${sender_address}",
        user        => $user,
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-26 01:30'},
    }

    cron { 'dumps-stats-sender':
        ensure => 'absent',
        user   => $user,
    }
}
