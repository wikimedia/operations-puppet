class snapshot::cron::shorturls(
    $user      = undef,
    $filesonly = false,
) {
    $cronsdir = $snapshot::dumps::dirs::cronsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    if !$filesonly {
        cron { 'shorturls':
            ensure      => absent,
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => "cd ${repodir}; python3 onallwikis.py --wiki metawiki --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat 'shorturls-{d}.gz' --outdir '${cronsdir}/shorturls' --script extensions/UrlShortener/maintenance/dumpURLs.php 'compress.zlib://{DIR}'",
            minute      => '5',
            hour        => '8',
            weekday     => '1',
        }
        systemd::timer::job { 'shorturls':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of short urls and their targets',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            working_directory  => $repodir,
            command            => "/usr/bin/python3 onallwikis.py --wiki metawiki --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat 'shorturls-{d}.gz' --outdir '${cronsdir}/shorturls' --script extensions/UrlShortener/maintenance/dumpURLs.php 'compress.zlib://{DIR}'",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 8:5:0'},
        }
    }
}
