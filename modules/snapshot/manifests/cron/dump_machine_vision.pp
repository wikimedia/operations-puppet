class snapshot::cron::dump_machine_vision(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dump-machine-vision.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump-machine-vision.sh',
    }

    if !$filesonly {
        cron { 'machine_vision_dump':
            ensure      => 'present',
            command     => "/usr/local/bin/dump-machine-vision.sh --config ${confsdir}/wikidump.conf.other",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '15',
            hour        => '9',
            weekday     => '6',
        }
    }
}
