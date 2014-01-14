class download::kiwix {
    # TODO: add system_role
    group { 'mirror':
        ensure => present,
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
        ensure => link,
        target => '/data/xmldatadumps/public/other/kiwix',
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0644',
    }

    cron { 'kiwix-mirror-update':
        ensure  => present,
        command => "rsync -vzrlptD  download.kiwix.org::download.kiwix.org/zim/0.9/ /data/xmldatadumps/public/other/kiwix/zim/0.9/ >/dev/null 2>&1",
        user    => 'mirror',
        minute  => '*/15',
    }
}
