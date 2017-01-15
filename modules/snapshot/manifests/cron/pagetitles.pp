class snapshot::cron::pagetitles(
    $user=undef,
) {
    include ::snapshot::dumps::dirs

    $otherdir = "${snapshot::dumps::dirs::datadir}/public/other"
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    cron { 'titles-cleanup':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${otherdir}/pagetitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\; ; find ${otherdir}/mediatitles/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    cron { 'pagetitles-ns0':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${repodir}; python onallwikis.py --configfile ${confsdir}/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${otherdir}/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
        minute      => '10',
        hour        => '8',
    }

    cron { 'pagetitles-ns6':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${repodir}; python onallwikis.py --configfile ${confsdir}/wikidump.conf.monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${otherdir}/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
        minute      => '50',
        hour        => '8',
    }

}
