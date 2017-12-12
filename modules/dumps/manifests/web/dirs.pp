class dumps::web::dirs(
    $datadir = undef,
    $xmldumpsdir = undef,
    $otherdir = undef,
    $user = undef,
    $group = undef,
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

    # top level dir
    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # top-level dirs for various dump trees
    file { [ $xmldumpsdir, $otherdir ]:
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
    file { [ $otherdir_wikibase, "${xmldumpsdir}/${relative_wikidatawiki}",
        $otherdir_wikidata_legacy ]:

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
