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

    # top level dir
    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # top-level dirs for various dump trees
    file { [ $publicdir, $otherdir ]:
        ensure => 'directory',
        mode   => '0775',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    # subdirs for various misc dumps
    file { [ $xlationdir, $cirrussearchdir, $medialistsdir,
             $pagetitlesdir, $categoriesrdf ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # subdirs for misc datasets that aren't dumps
    file { [ $analyticsdir, $othermiscdir, $othertestfilesdir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    # subdirs for wikidata/wikibase weekly dumps
    file { [ $otherdir_wikibase, "${publicdir}/${relative_wikidatawiki}",
             $otherdir_wikidata_legacy ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
    # T72385: needs to be relative because it is mounted via NFS at differing names
    file { "${publicdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${relative_wikidatawiki}",
    }
}
