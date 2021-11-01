class snapshot::systemdjobs::shorturls(
    $user      = undef,
    $filesonly = false,
) {
    $systemdjobsdir = $snapshot::dumps::dirs::systemdjobsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    if !$filesonly {
        systemd::timer::job { 'shorturls':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of short urls and their targets',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            working_directory  => $repodir,
            command            => "/usr/bin/python3 onallwikis.py --wiki metawiki --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat 'shorturls-{d}.gz' --outdir '${systemdjobsdir}/shorturls' --script extensions/UrlShortener/maintenance/dumpURLs.php 'compress.zlib://{DIR}'",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 8:5:0'},
        }
    }
}
