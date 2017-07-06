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

    file { '/data/xmldatadumps/public/kiwix':
        ensure => 'link',
        target => '/data/xmldatadumps/public/other/kiwix',
        owner  => 'datasets',
        group  => 'datasets',
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
        user        => 'datasets',
        minute      => '15',
        hour        => '*/2',
        require     => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
