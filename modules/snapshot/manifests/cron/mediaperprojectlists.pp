class snapshot::cron::mediaperprojectlists(
    $user   = undef,
) {
    include ::snapshot::dumps::dirs

    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/create-media-per-project-lists.sh',
        mode    => '0755',
        owner   => $user,
        group   => 'root',
        content => template('snapshot/cron/create-media-per-project-lists.sh.erb'),
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
