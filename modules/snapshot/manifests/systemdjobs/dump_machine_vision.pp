class snapshot::systemdjobs::dump_machine_vision(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dump-machine-vision.sh':
        ensure => absent,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/systemdjobs/dump-machine-vision.sh',
    }

    if !$filesonly {
        systemd::timer::job { 'machine_vision_dump':
            ensure             => absent,
            description        => 'Regular jobs to build snapshot of machine vision data',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "/usr/local/bin/dump-machine-vision.sh --config ${confsdir}/wikidump.conf.other",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sat *-*-* 9:15:0'},
        }
    }
}
