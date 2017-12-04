class snapshot::cron::mediaperprojectlists(
    $user   = undef,
) {
    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure => 'present',
        path   => '/usr/local/bin/create-media-per-project-lists.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/create-media-per-project-lists.sh',
    }

    cron { 'list-media-per-project':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/create-media-per-project-lists.sh',
        minute      => '10',
        hour        => '11',
        weekday     => '7',
    }
}
