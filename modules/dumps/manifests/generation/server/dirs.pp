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

    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $publicdir:
        ensure => 'directory',
        mode   => '0775',
        owner  => $user,
        group  => $group,
    }

    file { $otherdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $cirrussearchdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $xlationdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $deprecated_user,
        group  => $deprecated_group,
    }

    file { $categoriesrdfdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { $globalblocksdir:
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

    file { $incrsdir:
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

    file { $othermiscdir:
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

    file { $othertestfilesdir:
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
