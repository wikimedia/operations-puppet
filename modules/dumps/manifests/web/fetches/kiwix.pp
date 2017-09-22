class dumps::web::fetches::kiwix(
    $user = undef,
    $group = undef,
) {
    require_package('rsync')

    file { '/data/xmldatadumps/public/kiwix':
        ensure => 'link',
        target => '/data/xmldatadumps/public/other/kiwix',
        owner  => $user,
        group  => $group,
        mode   => '0644',
    }

    file { '/usr/local/bin/kiwix-rsync-cron.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/fetches/kiwix-rsync-cron.sh',
    }

    cron { 'kiwix-mirror-update':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => '/bin/bash /usr/local/bin/kiwix-rsync-cron.sh',
        user        => 'datasets',
        minute      => '15',
        hour        => '*/2',
        require     => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
