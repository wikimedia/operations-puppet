class dumps::web::xmldumps_active(
    $do_acme = true,
    $datadir = undef,
    $publicdir = undef,
    $otherdir = undef,
) {
    # active web server
    class {'::dumps::web::xmldumps':
        do_acme   => $do_acme,
        datadir   => $datadir,
        publicdir => $publicdir,
        otherdir  => $otherdir,
    }

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
    }
}
