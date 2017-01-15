class dataset::cron::kiwix(
    $enable = true,
) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include ::dataset::common

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

    file { '/usr/local/bin/kiwix-rsync-cron.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/kiwix-rsync-cron.sh',
    }

    cron { 'kiwix-mirror-update':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => '/bin/bash /usr/local/bin/kiwix-rsync-cron.sh',
        user        => 'mirror',
        minute      => '15',
        hour        => '*/2',
        require     => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
