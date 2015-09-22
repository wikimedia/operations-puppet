class dataset::dirs {
    # Please note that this is incomplete, but new directories
    # should be defined in puppet (here).
    $datadir = '/data/xmldatadumps'
    $publicdir = '/data/xmldatadumps/public'
    $otherdir = '/data/xmldatadumps/public/other'
    $othermiscdir = '/data/xmldatadumps/public/other/misc'
    $otherdir_wikidata_legacy = '/data/xmldatadumps/public/other/wikidata'
    $otherdir_wikibase = '/data/xmldatadumps/public/other/wikibase/'
    $relative_wikidatawiki = 'other/wikibase/wikidatawiki'

    file { $datadir:
        mode   => '0755',
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    file { $publicdir:
        mode   => '0775',
        ensure => 'directory',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir:
        mode   => '0755',
        ensure => 'directory',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $othermiscdir:
        mode   => '0755',
        ensure => 'directory',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir_wikibase:
        mode   => '0755',
        ensure => 'directory',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { "${publicdir}/${relative_wikidatawiki}":
        mode   => '0755',
        ensure => 'directory',
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
        mode   => '0755',
        ensure => 'directory',
        owner  => 'datasets',
        group  => 'datasets',
    }
}
