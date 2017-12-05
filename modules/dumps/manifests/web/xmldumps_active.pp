class dumps::web::xmldumps_active(
    $do_acme          = true,
    $datadir          = undef,
    $publicdir        = undef,
    $otherdir         = undef,
    $logs_dest        = undef,
    $htmldumps_server = undef,
    $xmldumps_server  = undef,
    $webuser          = undef,
    $webgroup         = undef,
    $deprecated_user  = undef,
    $deprecated_group = undef,
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
        deprecated_user  => $deprecated_user,
        deprecated_group => $deprecated_group,
    }

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => $logs_dest,
    }
}
