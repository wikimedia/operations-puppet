class dumps::web::dirs(
    $datadir = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
    $user = undef,
    $group = undef,
) {
    class {'dumps::server_dirs':
        datadir         = $datadir,
        xmldumpsdir     = $xmldumpsdir,
        miscdatasetsdir = $miscdatasetsdir,
        user            => $user,
        group           => $group,
    }

    $analyticsdir             = "${miscdatasetsdir}/analytics"
    $othermiscdir             = "${miscdatasetsdir}/misc"
    $othertestfilesdir        = "${miscdatasetsdir}/testfiles"
    $miscdatasetsdir_wikidata_legacy = "${miscdatasetsdir}/wikidata"
    $miscdatasetsdir_wikibase        = "${miscdatasetsdir}/wikibase/"
    $relative_wikidatawiki    = 'other/wikibase/wikidatawiki'

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
