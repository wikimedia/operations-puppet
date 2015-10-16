class dataset::cron::pagecountsraw(
    $enable = true,
    $source = undef,
    $user   = 'datasets',
) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }
    file { '/usr/local/bin/daily-pagestats-copy.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/pagecounts/daily-pagestats-copy.sh',
    }
    file { '/usr/local/bin/generate-pagecount-main-index.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/pagecounts/generate-pagecount-main-index.sh',
    }
    file { '/usr/local/bin/generate-pagecount-year-index.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/pagecounts/generate-pagecount-year-index.sh',
    }
    file { '/usr/local/bin/generate-pagecount-year-month-index.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/pagecounts/generate-pagecount-year-month-index.sh',
    }

    cron { 'pagestats-raw':
        ensure      => $ensure,
        command     => "/usr/local/bin/daily-pagestats-copy.sh ${user} ${source} /data/pagecounts/incoming/ /data/xmldatadumps/public/other/pagecounts-raw",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '21',
        require     => [
            File['/usr/local/bin/daily-pagestats-copy.sh'],
            File['/usr/local/bin/generate-pagecount-main-index.sh'],
            File['/usr/local/bin/generate-pagecount-year-index.sh'],
            File['/usr/local/bin/generate-pagecount-year-month-index.sh'],
            User[$user],
        ],
    }
}
