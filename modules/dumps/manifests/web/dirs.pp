class dumps::web::dirs(
    $datadir = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
    $user = undef,
    $group = undef,
) {
    # Please note that this is incomplete, but new directories
    # should be defined in puppet (here).
    $analyticsdir             = "${miscdatasetsdir}/analytics"
    $othermiscdir             = "${miscdatasetsdir}/misc"
    $othertestfilesdir        = "${miscdatasetsdir}/testfiles"
    $miscdatasetsdir_wikidata_legacy = "${miscdatasetsdir}/wikidata"
    $miscdatasetsdir_wikibase        = "${miscdatasetsdir}/wikibase/"
    $relative_wikidatawiki    = 'other/wikibase/wikidatawiki'
    $xlationdir               = "${miscdatasetsdir}/contenttranslation"
    $cirrussearchdir          = "${miscdatasetsdir}/cirrussearch"
    $medialistsdir            = "${miscdatasetsdir}/imageinfo"
    $pagetitlesdir            = "${miscdatasetsdir}/pagetitles"
    $mediatitlesdir           = "${miscdatasetsdir}/mediatitles"
    $categoriesrdf            = "${miscdatasetsdir}/categoriesrdf"

    # top level dir
    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # top-level dirs for various dump trees
    file { [ $xmldumpsdir, $miscdatasetsdir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
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
        owner  => $user,
        group  => $group,
    }

    # subdirs for wikidata/wikibase weekly dumps
    file { [ $miscdatasetsdir_wikibase, "${xmldumpsdir}/${relative_wikidatawiki}",
        $miscdatasetsdir_wikidata_legacy ]:

        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
    # T72385: needs to be relative because it is mounted via NFS at differing names
    file { "${xmldumpsdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${relative_wikidatawiki}",
    }
}
