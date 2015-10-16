class dataset::cron::kiwix($enable=true) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include dataset::common

    group { 'mirror':
        ensure => 'present',
    }

    user { 'mirror':
        name       => 'mirror',
        gid        => 'mirror',
        groups     => 'www-data',
        membership => minimum,
        home       => '/data/home',
        shell      => '/bin/bash',
    }

    file { '/data/xmldatadumps/public/kiwix':
        ensure => 'link',
        target => '/data/xmldatadumps/public/other/kiwix',
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0644',
    }

    cron { 'kiwix-mirror-update':
        ensure  => $ensure,
        command => 'rsync -vzrlptD --bwlimit=40000 download.kiwix.org::download.kiwix.org/zim/wikipedia/ /data/xmldatadumps/public/other/kiwix/zim/wikipedia/ >/dev/null 2>&1',
        user    => 'mirror',
        minute  => '15',
    }
}
