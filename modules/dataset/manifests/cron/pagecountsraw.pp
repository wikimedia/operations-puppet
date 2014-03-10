class dataset::cron::pagecountsraw(
    $enable = true,
    $key    = 'pagecounts_rsync_key',
    $user   = undef,
    $from   = undef
    ) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }
    system::role { 'dataset::cron::pagecountsraw':
        ensure      => $ensure,
        description => 'server of raw page view stats'
    }

    file { '/usr/local/bin/daily-pagestats-copy.sh':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/pagecounts/daily-pagestats-copy.sh',
    }
    file { '/usr/local/bin/generate-pagecount-main-index.sh':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/pagecounts/generate-pagecount-main-index.sh',
    }
    file { '/usr/local/bin/generate-pagecount-year-index.sh':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/pagecounts/generate-pagecount-year-index.sh',
    }
    file { '/usr/local/bin/generate-pagecount-year-month-index.sh':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/pagecounts/generate-pagecount-year-month-index.sh',
    }

    include accounts::datasets

    file { '/home/datasets/.ssh/pagecounts_rsync_key':
        mode    => '0400',
        owner   => 'datasets',
        group   => 'root',
        source  => 'puppet:///private/datasets/pagecounts_rsync_key',
    }

    cron { 'pagestats-raw':
        ensure  => $ensure,
        command => "/usr/local/bin/daily-pagestats-copy.sh ${user} /home/${user}/.ssh/${key} ${from} /a/webstats/dumps /data/pagecounts/incoming /data/xmldatadumps/public/other/pagecounts-raw",
        user    => $user,
        minute  => '21',
        require => [File['/usr/local/bin/daily-pagestats-copy.sh'],
                   File['/usr/local/bin/generate-pagecount-main-index.sh'],
                   File['/usr/local/bin/generate-pagecount-year-index.sh'],
                   File['/usr/local/bin/generate-pagecount-year-month-index.sh'],
                   File['/home/datasets/.ssh/pagecounts_rsync_key']],
    }
}
