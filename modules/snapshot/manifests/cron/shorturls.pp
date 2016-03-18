class snapshot::cron::shorturls(
    $user=undef,
) {
    include snapshot::dumps::dirs

    $shorturlsdir = "${snapshot::dumps::dirs::datadir}/public/other/shorturls"
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { $shorturlsdir:
        ensure => 'directory',
        path   => $shorturlsdir,
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'shorturls-cleanup':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${shorturlsdir}/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    cron { 'shorturls':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${repodir}; python onallwikis.py --wiki metawiki --configfile ${confsdir}/wikidump.conf.monitor  --filenameformat 'shorturls-{d}.txt' --outdir '${shorturlsdir}' --script extensions/UrlShortener/maintenance/dumpURLs.php '{DIR}'",
        minute      => '5',
        hour        => '8',
        weekday     => '1',
        require     => File[$shorturlsdir],
    }
}
