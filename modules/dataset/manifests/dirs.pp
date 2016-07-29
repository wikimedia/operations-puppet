class dataset::dirs {
    # Please note that this is incomplete, but new directories
    # should be defined in puppet (here).
    $datadir                  = '/data/xmldatadumps'
    $publicdir                = '/data/xmldatadumps/public'
    $otherdir                 = '/data/xmldatadumps/public/other'
    $analyticsdir             = '/data/xmldatadumps/public/other/analytics'
    $othermiscdir             = '/data/xmldatadumps/public/other/misc'
    $othertestfilesdir        = '/data/xmldatadumps/public/other/testfiles'
    $otherdir_wikidata_legacy = '/data/xmldatadumps/public/other/wikidata'
    $otherdir_wikibase        = '/data/xmldatadumps/public/other/wikibase/'
    $relative_wikidatawiki    = 'other/wikibase/wikidatawiki'
    $xlationdir               = '/data/xmldatadumps/public/other/xlation/'

    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $publicdir:
        ensure => 'directory',
        mode   => '0775',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $analyticsdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $othermiscdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $othertestfilesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir_wikibase:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { "${publicdir}/${relative_wikidatawiki}":
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    # T72385
    # needs to be relative because it is mounted via NFS at differing names
    file { "${publicdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${relative_wikidatawiki}"
    }

    # Legacy
    file { $otherdir_wikidata_legacy:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $xlationdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }
}
