class snapshot::dirs {
    $dumpsdir = '/srv/dumps'
    $datadir = '/mnt/data/xmldatadumps'
    $apachedir = '/srv/mediawiki'

    file { $dumpsdir:
        ensure => 'directory',
        path   => $dumpsdir,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    $addschangesdir = '/srv/addschanges'

    file { $addschangesdir:
        ensure => 'directory',
        path   => $addschangesdir,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    $wikiqueriesdir = '/srv/wikiqueries'

    file { $wikiqueriesdir:
        ensure => 'directory',
        path   => $wikiqueriesdir,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

}
