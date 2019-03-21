class snapshot::cron::dump_global_blocks(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dump-global-blocks.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump-global-blocks.sh',
    }

    if !$filesonly {
        cron { 'global_blocks_dump':
            ensure      => 'present',
            command     => "/usr/local/bin/dump-global-blocks.sh --config ${confsdir}/wikidump.conf.other",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '15',
            hour        => '8',
            weekday     => '6',
        }
    }
}
