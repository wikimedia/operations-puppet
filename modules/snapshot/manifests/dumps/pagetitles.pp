class snapshot::dumps::pagetitles(
    $enable=true,
    $user=undef,
) {
    include snapshot::dumps::dirs
    include snapshot::wikiqueryskip

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { "${snapshot::dumps::dirs::datadir}/public/other/pagetitles":
        ensure => 'directory',
        path   => "${snapshot::dumps::dirs::datadir}/public/other/pagetitles",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    file { "${snapshot::dumps::dirs::datadir}/public/other/mediatitles":
        ensure => 'directory',
        path   => "${snapshot::dumps::dirs::datadir}/public/other/mediatitles",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'titles-cleanup':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${snapshot::dumps::dirs::datadir}/public/other/pagetitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\; ; find ${snapshot::dumps::dirs::datadir}/public/other/mediatitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    cron { 'pagetitles-ns0':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dumps::dirs::scriptsdir}; python onallwikis.py --configfile confs/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${snapshot::dumps::dirs::datadir}/public/other/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
        minute      => '10',
        hour        => '8',
        require     => File["${snapshot::dumps::dirs::datadir}/public/other/pagetitles"],
    }

    cron { 'pagetitles-ns6':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dumps::dirs::scriptsdir}; python onallwikis.py --configfile confs/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${snapshot::dumps::dirs::datadir}/public/other/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
        minute      => '50',
        hour        => '8',
        require     => File["${snapshot::dumps::dirs::datadir}/public/other/mediatitles"],
    }

}
