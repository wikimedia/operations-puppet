class dumps::web::xmldumps_active(
    $do_acme          = true,
    $datadir          = undef,
    $xmldumpsdir      = undef,
    $miscdatasetsdir  = undef,
    $logs_dest        = undef,
    $htmldumps_server = undef,
    $xmldumps_server  = undef,
    $webuser          = undef,
    $webgroup         = undef,
) {
    # active web server
    class {'::dumps::web::xmldumps':
        do_acme          => $do_acme,
        datadir          => $datadir,
        xmldumpsdir      => $xmldumpsdir,
        miscdatasetsdir  => $miscdatasetsdir,
        htmldumps_server => $htmldumps_server,
        xmldumps_server  => $xmldumps_server,
        webuser          => $webuser,
        webgroup         => $webgroup,
    }

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => $logs_dest,
    }
}
