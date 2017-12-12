class dumps::generation::server::dirs(
    $datadir     = undef,
    $xmldumpsdir = undef,
    $tempdir     = undef,
    $otherdir    = undef,
    $user        = undef,
    $group       = undef,
) {
    # Directories where dumps of any type are generated
    # This list is not for one-off directories, nor for
    # directories with incoming rsyncs of datasets
    $cirrussearchdir              = "${otherdir}/cirrussearch"
    $xlationdir                   = "${otherdir}/contenttranslation"
    $categoriesrdfdir             = "${otherdir}/categoriesrdf"
    $globalblocksdir              = "${otherdir}/globalblocks"
    $medialistsdir                = "${otherdir}/imageinfo"
    $incrsdir                     = "${otherdir}/incr"
    $mediatitlesdir               = "${otherdir}/mediatitles"
    $othermiscdir                 = "${otherdir}/misc"
    $pagetitlesdir                = "${otherdir}/pagetitles"
    $othertestfilesdir            = "${otherdir}/testfiles"
    $otherwikibasedir             = "${otherdir}/wikibase"
    $otherwikibasewikidatadir     = "${otherdir}/wikibase/wikidatawiki"
    $otherwikidatadir             = "${otherdir}/wikidata"

    # top level directories for various dumps/datasets
    file { [ $datadir, $xmldumpsdir, $otherdir, $tempdir ]:
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
