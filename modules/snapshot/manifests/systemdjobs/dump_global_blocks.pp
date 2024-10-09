class snapshot::systemdjobs::dump_global_blocks(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dump-global-blocks.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/systemdjobs/dump-global-blocks.sh',
    }

    if !$filesonly {
        systemd::timer::job { 'global_blocks_dump':
            ensure             => absent,
            description        => 'Regular jobs to build snapshot of globally blocked users',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "/usr/local/bin/dump-global-blocks.sh --config ${confsdir}/wikidump.conf.other",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sat *-*-* 8:15:0'},
        }
    }
}
