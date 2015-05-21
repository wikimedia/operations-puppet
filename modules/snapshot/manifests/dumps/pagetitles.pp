class snapshot::dumps::pagetitles(
    $enable=true,
    $user=undef,
) {
    include snapshot::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::dumps::pagetitles':
        ensure      => $ensure,
        description => 'producer of daily page title files'
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
    file { "${snapshot::dirs::wikiqueriesdir}/confs":
        ensure => 'directory',
        path   => "${snapshot::dirs::wikiqueriesdir}/confs",
        mode   => '0755',
        owner  => $user,
        group  => root,
    }
    file { "${snapshot::dirs::wikiqueriesdir}/confs/wq.conf":
        ensure  => 'present',
        path    => "${snapshot::dirs::wikiqueriesdir}/confs/wq.conf",
        mode    => '0644',
        owner   => $user,
        group   => root,
        content => template('snapshot/wq.conf.erb'),
    }

    cron { 'pagetitles-ns0':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dirs::wikiqueriesdir}; python wikiqueries.py --configfile confs/wq.conf  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${snapshot::dirs::datadir}/public/other/pagetitles/{d}' --query 'select page_title from page where page_namespace=0;'",
        minute      => '10',
        hour        => '8',
        require     => File["${snapshot::dirs::datadir}/public/other/pagetitles"],
    }

    cron { 'pagetitles-ns6':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "cd ${snapshot::dirs::wikiqueriesdir}; python wikiqueries.py --configfile confs/wq.conf  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${snapshot::dirs::datadir}/public/other/mediatitles/{d}' --query 'select page_title from page where page_namespace=6;'",
        minute      => '50',
        hour        => '8',
        require     => File["${snapshot::dirs::datadir}/public/other/mediatitles"],
    }
}
