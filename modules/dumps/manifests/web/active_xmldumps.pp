class dumps::web::active_xmldumps {
    # active web server

    include ::dumps::web::xmldumps

    # only the active web server should be syncing nginx logs
    class {'::dumps::web::rsync::nginxlogs':
        dest   => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
    }
}
