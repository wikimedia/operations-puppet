class snapshot::dumps::mediadirlists(
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

    system::role { 'snapshot::dumps::mediadirlists':
        ensure      => $ensure,
        description => 'producer of daily lists of media directories'
    }

    file { '/usr/local/bin/create-mediadir-list.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/create-mediadir-list.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/create-mediadir-list.sh.erb'),
    }

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.monitor, make explicit
    cron { 'list-media-dirs':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/create-mediadir-list.sh',
        minute      => '10',
        hour        => '2',
    }
}
