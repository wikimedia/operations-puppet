class dumpsdirs(
    $user  = undef,
    $group = undef,
) {
    # Directories where dumps of any type are generated
    $datadir                      = '/data/xmldatadumps'
    $publicdir                    = '/data/xmldatadumps/public'
    $otherdir                     = "${publicdir}/other"
    $analyticsdir                 = "${otherdir}/analytics"
    $cirrussearchdir              = "${otherdir}/cirrussearch"
    $xlationdir                   = "${otherdir}/contenttranslation"
    $globalblocksdir              = "${otherdir}/globalblocks"
    $medialistsdir                = "${otherdir}/imageinfo"
    $mediatitlesdir               = "${otherdir}/mediatitles"
    $pagetitlesdir                = "${otherdir}/pagetitles"
    $othermiscdir                 = "${otherdir}/misc"
    $othertestfilesdir            = "${otherdir}/testfiles"
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

    file { $analyticsdir:
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

    file { $otherwikibasedir:
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

    # Legacy
    file { $otherwikidatalegacydir:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
