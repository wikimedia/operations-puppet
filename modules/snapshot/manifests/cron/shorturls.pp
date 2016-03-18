class snapshot::cron::shorturls(
    $enable=true,
    $user=undef,
) {
    include snapshot::dumps::dirs
    include snapshot::cron::wikiqueryskip

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $shorturlsdir = "${snapshot::dumps::dirs::datadir}/public/other/shorturls"

    file { $shorturlsdir:
        ensure => 'directory',
        path   => $shorturlsdir,
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'shorturls-cleanup':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find $shorturlsdir/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    cron { 'shorturls':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dumps::dirs::scriptsdir}; python onallwikis.py --wiki metawiki --configfile confs/wikidump.conf.monitor  --filenameformat 'shorturls-{d}.txt' --outdir '$shorturlsdir' --script extensions/UrlShortener/maintenance/dumpURLs.php '{DIR}'",
        minute      => '5',
        hour        => '8',
        weekday     => '1',
        require     => File[$shorturlsdir],
    }
}
