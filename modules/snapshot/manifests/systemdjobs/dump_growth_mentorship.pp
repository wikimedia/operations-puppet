class snapshot::systemdjobs::dump_growth_mentorship(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dump-growth-mentorship.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/systemdjobs/dump-growth-mentorship.sh',
    }

    if !$filesonly {
        systemd::timer::job { 'growth_mentorship_dump':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of Growth-team mentorship',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "/usr/local/bin/dump-growth-mentorship.sh --config ${confsdir}/wikidump.conf.other",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sat *-*-* 8:15:0'},
        }
    }
}
