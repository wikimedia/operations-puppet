class dumps::generation::server::dirs(
    $datadir         = undef,
    $xmldumpsdir     = undef,
    $tempdir         = undef,
    $miscdatasetsdir = undef,
    $user            = undef,
    $group           = undef,
) {
    class {'dumps::server_dirs':
        datadir         => $datadir,
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
        user            => $user,
        group           => $group,
    }

    # Directories where dumps of any type are generated
    # This list is not for one-off directories, nor for
    # directories with incoming rsyncs of datasets
    $cirrussearchdir              = "${miscdatasetsdir}/cirrussearch"
    $xlationdir                   = "${miscdatasetsdir}/contenttranslation"
    $categoriesrdfdir             = "${miscdatasetsdir}/categoriesrdf"
    $categoriesrdfdailydir        = "${miscdatasetsdir}/categoriesrdf/daily"
    $globalblocksdir              = "${miscdatasetsdir}/globalblocks"
    $medialistsdir                = "${miscdatasetsdir}/imageinfo"
    $incrsdir                     = "${miscdatasetsdir}/incr"
    $machinevisiondir             = "${miscdatasetsdir}/machinevision"
    $mediatitlesdir               = "${miscdatasetsdir}/mediatitles"
    $pagetitlesdir                = "${miscdatasetsdir}/pagetitles"
    $shorturlsdir                 = "${miscdatasetsdir}/shorturls"
    $otherwikibasedir             = "${miscdatasetsdir}/wikibase"
    $otherwikibasewikidatadir     = "${miscdatasetsdir}/wikibase/wikidatawiki"
    $otherwikidatadir             = "${miscdatasetsdir}/wikidata"
    $otherwikibasecommonsdir      = "${miscdatasetsdir}/wikibase/commonswiki"
    $othercommonsdir              = "${miscdatasetsdir}/commons"

    # top level directories for various dumps/datasets, on generation hosts only
    file { $tempdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # subdirs for various generated dumps
    file { [ $cirrussearchdir, $xlationdir, $categoriesrdfdir,
        $categoriesrdfdailydir, $globalblocksdir, $medialistsdir, $incrsdir,
        $mediatitlesdir, $pagetitlesdir, $shorturlsdir, $machinevisiondir ]:

        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # needed for wikidata weekly crons
    file { [ $otherwikibasedir, $otherwikibasewikidatadir, $otherwikidatadir,
        $otherwikibasecommonsdir, $othercommonsdir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
