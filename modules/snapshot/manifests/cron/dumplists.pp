class snapshot::cron::dumplists(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/list-last-good-dumps.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/list-last-good-dumps.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/list-last-good-dumps.sh.erb'),
    }
    file { '/usr/local/bin/list-last-n-good-dumps.py':
        ensure => 'present',
        path   => '/usr/local/bin/list-last-n-good-dumps.py',
        mode   => '0755',
        owner  => $user,
        group  => root,
        source => 'puppet:///modules/snapshot/cron/list-last-n-good-dumps.py',
    }

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.monitor, make explicit
    cron { 'list-good-dumps':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/list-last-good-dumps.sh',
        minute      => '55',
        hour        => '3',
    }
}
