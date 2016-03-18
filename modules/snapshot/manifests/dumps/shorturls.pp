class snapshot::dumps::shorturls(
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

    file { "${snapshot::dirs::datadir}/public/other/shorturls":
        ensure => 'directory',
        path   => "${snapshot::dirs::datadir}/public/other/shorturls",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }

    cron { 'shorturls-cleanup':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "find ${snapshot::dirs::datadir}/public/other/shorturls/ -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \\;",
        minute      => '0',
        hour        => '8',
    }

    cron { 'shorturls':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dirs::dumpsdir}; python onallwikis.py --wiki bewikibooks --configfile confs/wikidump.conf.monitor  --filenameformat 'shorturls-{d}.txt' --outdir '${snapshot::dirs::datadir}/public/other/shorturls' --script extensions/UrlShortener/maintenance/dumpURLs.php '{DIR}'",
        minute      => '5',
        hour        => '8',
        require     => File["${snapshot::dirs::datadir}/public/other/shorturls"],
    }
}
