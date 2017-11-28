class dumps::web::xmldumps_active(
    $do_acme          = true,
    $datadir          = undef,
    $publicdir        = undef,
    $otherdir         = undef,
    $logs_dest        = undef,
    $htmldumps_server = undef,
    $xmldumps_server  = undef,
    $wikilist_url     = undef,
    $wikilist_dir     = undef,
    $user             = undef,
    $webuser          = undef,
    $webgroup         = undef,
) {
    # active web server
    class {'::dumps::web::xmldumps':
        do_acme          => $do_acme,
        datadir          => $datadir,
        publicdir        => $publicdir,
        otherdir         => $otherdir,
        htmldumps_server => $htmldumps_server,
        xmldumps_server  => $xmldumps_server,
        webuser          => $webuser,
        webgroup         => $webgroup,
    }

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => $logs_dest,
    }

    # only the active web server needs to cleanup old files
    # rsync between peers will take care of the other hosts
    class {'::dumps::web::cleanups::xml_cleanup':
        wikilist_url => $wikilist_url,
        wikilist_dir => $wikilist_dir,
        publicdir    => $publicdir,
        user         => $user,
    }

}
