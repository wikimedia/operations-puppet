class dumps::generation::server::dirs(
    $user  = undef,
    $group = undef,
    $deprecated_user = undef,
    $deprecated_group = undef,
) {
    # Directories where dumps of any type are generated
    # This list is not for one-off directories, nor for
    # directories with incoming rsyncs of datasets
    $datadir                      = '/data/xmldatadumps'
    $publicdir                    = '/data/xmldatadumps/public'
    $otherdir                     = '/data/otherdumps'
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
    $wikidatawikidir              = "${publicdir}/wikidatawiki"
    $otherwikibasedir             = "${otherdir}/wikibase"

    # top level directories for various dumps/datasets
    file { [ $datadir, $publicdir, $otherdir ]:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
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

    file { $otherwikibasedir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
