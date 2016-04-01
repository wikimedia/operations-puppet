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

    $otherdir = "${snapshot::dumps::dirs::datadir}/public/other/pagetitles"

    file { $otherdir:
        ensure => 'directory',
        path   => $otherdir,
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    file { "${otherdir}/mediatitles":
        ensure => 'directory',
        path   => "${otherdir}/mediatitles",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'titles-cleanup':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${otherdir}/pagetitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\; ; find ${otherdir}/mediatitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    $scriptsdir = $snapshot::dumps::dirs::scriptsdir

    cron { 'pagetitles-ns0':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${scriptsdir}; python onallwikis.py --configfile confs/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${otherdir}/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
        minute      => '10',
        hour        => '8',
        require     => File["${otherdir}/pagetitles"],
    }

    cron { 'pagetitles-ns6':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${scriptsdir}; python onallwikis.py --configfile confs/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${otherdir}/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
        minute      => '50',
        hour        => '8',
        require     => File["${otherdir}/mediatitles"],
    }

}
