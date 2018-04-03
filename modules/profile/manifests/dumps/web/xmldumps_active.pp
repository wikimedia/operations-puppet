# Profile applied to the current dataset serving hosts
# Can be deprecated after migrating to labstore1006|7
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
}
