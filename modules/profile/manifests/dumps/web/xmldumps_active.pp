class profile::dumps::web::xmldumps_active {
    require profile::dumps::web::xmldumps_common

    # copy dumps web server logs to stat host
    class {'::dumps::web::rsync::nginxlogs':
        dest => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
    }

    # copy dumps and other datasets to fallback host(s) and to labs
    class {'::dumps::copying::peers':
        desthost => 'ms1001.wikimedia.org',
    }
    class {'::dumps::copying::labs':
        labhost         => 'labstore1003.eqiad.wmnet',
        xmldumpsdir     => $profile::dumps::web::xmldumps_common::xmldumpsdir,
        miscdatasetsdir => $profile::dumps::web::xmldumps_common::miscdatasetsdir,
    }
}
