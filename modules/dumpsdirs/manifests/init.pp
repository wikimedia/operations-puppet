class dumpsdirs(
    $user  = undef,
    $group = undef,
) {
    # Directories where dumps of any type are generated
    # This list is not for one-off directories, nor for
    # directories with incoming rsyncs of datasets
    $datadir                      = '/data/xmldatadumps'
    $publicdir                    = '/data/xmldatadumps/public'
    $otherdir                     = "${publicdir}/other"
    $cirrussearchdir              = "${otherdir}/cirrussearch"
    $xlationdir                   = "${otherdir}/contenttranslation"
    $globalblocksdir              = "${otherdir}/globalblocks"
    $medialistsdir                = "${otherdir}/imageinfo"
    $incrsdir                     = "${otherdir}/incrs"
    $mediatitlesdir               = "${otherdir}/mediatitles"
    $othermiscdir                 = "${otherdir}/misc"
    $pagetitlesdir                = "${otherdir}/pagetitles"
    $othertestfilesdir            = "${otherdir}/testfiles"
    $wikidatawikidir              = "${otherdir}/wikidatawiki"
    $otherwikibasedir             = "${otherdir}/wikibase/"
    $otherwikidatalegacydir       = "${otherdir}/wikidata"
    $otherwikidatawikirelativedir  = 'other/wikibase/wikidatawiki'

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

    ########################
    #
    # wikidata-related items
    #
    ########################

    # although this directory would be created in the course
    # of xml dumps runs, we must create it here so that symlinks
    # for the other types of wikidata dumps can be made
    file { $wikidatawikidir:
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

    # Legacy
    file { $otherwikidatalegacydir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    file { "${publicdir}/${otherwikidatawikirelativedir}":
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    # T72385
    # needs to be relative so that it can be referenced on dumpsdata hosts
    # via the path $publicdir/... and on the snapshot hosts via
    # via NFS mount path /mnt$publicdir/...
    file { "${publicdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${otherwikidatawikirelativedir}",
    }

}
