class snapshot::mediaperprojectlists(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::mediaperprojectlists':
        ensure      => $ensure,
        description => 'producer of weekly lists of media per project'
    }

    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/create-media-per-project-lists.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/create-media-per-project-lists.sh.erb'),
    }

    cron { 'list-media-per-project':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/create-media-per-project-lists.sh',
        minute      => '10',
        hour        => '11',
        weekday     => '7',
    }
}
