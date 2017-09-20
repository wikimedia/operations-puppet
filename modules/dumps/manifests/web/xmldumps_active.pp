class dumps::web::xmldumps_active(
    $do_acme = true,
) {
    # active web server
    class {'::dumps::web::xmldumps': $do_acme => $do_acme}

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
    }
}
