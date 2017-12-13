class profile::dumps::web::xmldumps_active(
    $do_acme = hiera('do_acme'),
) {
    class { '::dumpsuser': }
    $xmldumpsdir = '/data/xmldatadumps/public'
    $miscdatasetsdir = '/data/xmldatadumps/public/other'

    class {'::dumps::web::xmldumps_active':
        do_acme          => $do_acme,
        datadir          => '/data/xmldatadumps',
        xmldumpsdir      => $xmldumpsdir,
        miscdatasetsdir  => '/data/xmldatadumps/public/other',
        logs_dest        => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
        htmldumps_server => 'francium.eqiad.wmnet',
        xmldumps_server  => 'dumps.wikimedia.org',
        webuser          => 'dumpsgen',
        webgroup         => 'dumpsgen',
    }
    # copy dumps and other datasets to fallback host(s) and to labs
    class {'::dumps::copying::peers':
        desthost => 'ms1001.wikimedia.org',
    }
    class {'::dumps::copying::labs':
        labhost         => 'labstore1003.eqiad.wmnet',
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
    }
}
