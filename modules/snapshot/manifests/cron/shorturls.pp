class snapshot::cron::shorturls(
    $user      = undef,
    $filesonly = false,
) {
    $cronsdir = $snapshot::dumps::dirs::cronsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    if !$filesonly {
        cron { 'shorturls':
            ensure      => 'present',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => "cd ${repodir}; python3 onallwikis.py --wiki metawiki --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat 'shorturls-{d}.gz' --outdir '${cronsdir}/shorturls' --script extensions/UrlShortener/maintenance/dumpURLs.php 'compress.zlib://{DIR}'",
            minute      => '5',
            hour        => '8',
            weekday     => '1',
        }
    }
}
