class dumps::generation::server::dirs(
    $datadir         = undef,
    $xmldumpsdir     = undef,
    $tempdir         = undef,
    $miscdatasetsdir = undef,
    $user            = undef,
    $group           = undef,
) {
    # Directories where dumps of any type are generated
    # This list is not for one-off directories, nor for
    # directories with incoming rsyncs of datasets
    $cirrussearchdir              = "${miscdatasetsdir}/cirrussearch"
    $xlationdir                   = "${miscdatasetsdir}/contenttranslation"
    $categoriesrdfdir             = "${miscdatasetsdir}/categoriesrdf"
    $globalblocksdir              = "${miscdatasetsdir}/globalblocks"
    $medialistsdir                = "${miscdatasetsdir}/imageinfo"
    $incrsdir                     = "${miscdatasetsdir}/incr"
    $mediatitlesdir               = "${miscdatasetsdir}/mediatitles"
    $othermiscdir                 = "${miscdatasetsdir}/misc"
    $pagetitlesdir                = "${miscdatasetsdir}/pagetitles"
    $othertestfilesdir            = "${miscdatasetsdir}/testfiles"
    $otherwikibasedir             = "${miscdatasetsdir}/wikibase"
    $otherwikibasewikidatadir     = "${miscdatasetsdir}/wikibase/wikidatawiki"
    $otherwikidatadir             = "${miscdatasetsdir}/wikidata"

    # top level directories for various dumps/datasets
    file { [ $datadir, $xmldumpsdir, $miscdatasetsdir, $tempdir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # subdirs for various dumps
    file { [ $cirrussearchdir, $xlationdir, $categoriesrdfdir,
        $globalblocksdir, $medialistsdir, $incrsdir,
        $mediatitlesdir, $othermiscdir, $pagetitlesdir,
        $othertestfilesdir ]:

        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # needed for wikidata weekly crons
    file { [ $otherwikibasedir, $otherwikibasewikidatadir, $otherwikidatadir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
