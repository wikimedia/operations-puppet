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
    systemd::timer::job { 'list-good-dumps':
        ensure             => present,
        description        => 'Regular jobs to list good dumps',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/local/bin/list-last-good-dumps.sh --xmldumpsdir ${xmldumpsdir}",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:55:0'},
    }
}
