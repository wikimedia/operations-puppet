class snapshot::cron::pagetitles(
    $user      = undef,
    $filesonly = false,
) {
    $cronsdir = $snapshot::dumps::dirs::cronsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    if !$filesonly {
        cron { 'pagetitles-ns0':
            ensure      => 'present',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => "cd ${repodir}; python3 onallwikis.py --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${cronsdir}/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
            minute      => '10',
            hour        => '8',
        }

        cron { 'pagetitles-ns6':
            ensure      => 'present',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => "cd ${repodir}; python3 onallwikis.py --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${cronsdir}/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
            minute      => '50',
            hour        => '8',
        }
    }
}
