class snapshot::dumps::pagetitles(
    $enable=true,
    $user=undef,
) {
    include snapshot::dirs
    include snapshot::wikiqueryskip

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { "${snapshot::dirs::datadir}/public/other/pagetitles":
        ensure => 'directory',
        path   => "${snapshot::dirs::datadir}/public/other/pagetitles",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    file { "${snapshot::dirs::datadir}/public/other/mediatitles":
        ensure => 'directory',
        path   => "${snapshot::dirs::datadir}/public/other/mediatitles",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'pagetitles-ns0':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dirs::dumpsdir}; python onallwikis.py --configfile confs/wikidump.conf  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${snapshot::dirs::datadir}/public/other/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
        minute      => '10',
        hour        => '8',
        require     => File["${snapshot::dirs::datadir}/public/other/pagetitles"],
    }

    cron { 'pagetitles-ns6':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dirs::dumpsdir}; python onallwikis.py --configfile confs/wikidump.conf  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${snapshot::dirs::datadir}/public/other/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
        minute      => '50',
        hour        => '8',
        require     => File["${snapshot::dirs::datadir}/public/other/mediatitles"],
    }
}
