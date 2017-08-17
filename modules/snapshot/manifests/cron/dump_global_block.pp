class snapshot::cron::dump_global_block(
    $user   = undef,
) {
    include ::snapshot::dumps::dirs
    $confsdir = $snapshot::dumps::dirs::confsdir
    $otherdir = "${snapshot::dumps::dirs::datadir}/public/other"
    $globalblockdir = "${otherdir}/globalblock"

    file { '/usr/local/bin/dump-global-block.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump-global-block.sh',
    }

    cron { 'global_block_cleanup':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${globalblockdir}/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
        weekday     => '6',
    }

    cron { 'global_block_dump':
        ensure      => 'present',
        command     => "/usr/local/bin/dump-global-block.sh --config ${confsdir}/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
    }
}
