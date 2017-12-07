class dumps::web::dumplists(
    $xmldumpsdir = undef,
    $user   = undef,
) {
    file { '/usr/local/bin/list-last-good-dumps.sh':
        ensure => 'present',
        path   => '/usr/local/bin/list-last-good-dumps.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/list-last-good-dumps.sh',
    }
    file { '/usr/local/bin/list-last-n-good-dumps.py':
        ensure => 'present',
        path   => '/usr/local/bin/list-last-n-good-dumps.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/list-last-n-good-dumps.py',
    }

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.monitor, make explicit
    cron { 'list-good-dumps':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/list-last-good-dumps.sh ${xmldumpsdir}",
        minute      => '55',
        hour        => '3',
    }
}
