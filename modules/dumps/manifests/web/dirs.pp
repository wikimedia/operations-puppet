class dumps::web::dirs(
    $datadir = '/data/xmldatadumps',
    $publicdir = '/data/xmldatadumps/public',
    $otherdir = '/data/xmldatadumps/public/other',
    $user = undef,
    $group = undef,
    $deprecated_user = undef,
    $deprecated_group = undef,
) {
    # Please note that this is incomplete, but new directories
    # should be defined in puppet (here).
    $analyticsdir             = "${otherdir}/analytics"
    $othermiscdir             = "${otherdir}/misc"
    $othertestfilesdir        = "${otherdir}/testfiles"
    $otherdir_wikidata_legacy = "${otherdir}/wikidata"
    $otherdir_wikibase        = "${otherdir}/wikibase/"
    $relative_wikidatawiki    = 'other/wikibase/wikidatawiki'
    $xlationdir               = "${otherdir}/contenttranslation"
    $cirrussearchdir          = "${otherdir}/cirrussearch"
    $medialistsdir            = "${otherdir}/imageinfo"
    $pagetitlesdir            = "${otherdir}/pagetitles"
    $mediatitlesdir           = "${otherdir}/mediatitles"
    $categoriesrdf            = "${otherdir}/categoriesrdf"

    include dumps::deprecated::user

    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $publicdir:
        ensure => 'directory',
        mode   => '0775',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $otherdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $analyticsdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $othermiscdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $othertestfilesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $otherdir_wikibase:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { "${publicdir}/${relative_wikidatawiki}":
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    # T72385
    # needs to be relative because it is mounted via NFS at differing names
    file { "${publicdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${relative_wikidatawiki}",
    }

    # Legacy
    file { $otherdir_wikidata_legacy:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $xlationdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $cirrussearchdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $medialistsdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $mediatitlesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $pagetitlesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $categoriesrdf:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
