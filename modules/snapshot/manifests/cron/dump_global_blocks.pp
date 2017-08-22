class snapshot::cron::dump_global_blocks(
    $user   = undef,
) {
    include ::snapshot::dumps::dirs
    $confsdir = $snapshot::dumps::dirs::confsdir
    $otherdir = "${snapshot::dumps::dirs::datadir}/public/other"
    $globalblocksdir = "${otherdir}/globalblocks"

    file { '/usr/local/bin/dump-global-blocks.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump-global-blocks.sh',
    }

    cron { 'global_blocks_cleanup':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${globalblocksdir}/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
        weekday     => '6',
    }

    cron { 'global_blocks_dump':
        ensure      => 'present',
        command     => "/usr/local/bin/dump-global-blocks.sh --config ${confsdir}/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
    }
}
