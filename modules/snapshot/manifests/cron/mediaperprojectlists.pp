class snapshot::cron::mediaperprojectlists(
    $user      = undef,
    $filesonly = false,
) {
    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure => 'present',
        path   => '/usr/local/bin/create-media-per-project-lists.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/create-media-per-project-lists.sh',
    }

    if !$filesonly {
        systemd::timer::job { 'list-media-per-project':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of media tables (image, globalimagelink, ...)',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => '/usr/local/bin/create-media-per-project-lists.sh',
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sun *-*-* 7:10:0'},
        }
    }
}
