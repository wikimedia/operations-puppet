class snapshot::cron::dumplists(
    $user   = undef,
) {
    include ::snapshot::dumps::dirs

    file { '/usr/local/bin/list-last-good-dumps.sh':
        ensure => 'present',
        path   => '/usr/local/bin/list-last-good-dumps.sh',
        mode   => '0755',
        owner  => $user,
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/list-last-good-dumps.sh',
    }
    file { '/usr/local/bin/list-last-n-good-dumps.py':
        ensure => 'present',
        path   => '/usr/local/bin/list-last-n-good-dumps.py',
        mode   => '0755',
        owner  => $user,
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/list-last-n-good-dumps.py',
    }

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.monitor, make explicit
    cron { 'list-good-dumps':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/list-last-good-dumps.sh',
        minute      => '55',
        hour        => '3',
    }
}
