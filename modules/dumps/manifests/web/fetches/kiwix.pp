class dumps::web::fetches::kiwix(
    $publicdir = undef,
    $otherdir = undef,
) {
    include dumps::deprecated::user
    require_package('rsync')

    file { "${publicdir}/kiwix":
        ensure => 'link',
        target => "${otherdir}/kiwix",
        owner  => 'datasets',
        group  => 'datasets',
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
        command     => "/bin/bash /usr/local/bin/kiwix-rsync-cron.sh ${otherdir}",
        user        => 'datasets',
        minute      => '15',
        hour        => '*/2',
        require     => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
