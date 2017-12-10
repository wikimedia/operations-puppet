class profile::dumps::web::xmldumps_active {
    class { '::dumpsuser': }
    $publicdir = '/data/xmldatadumps/public'
    $otherdir = '/data/xmldatadumps/public/other'

    class {'::dumps::web::xmldumps_active':
        do_acme          => hiera('do_acme'),
        datadir          => '/data/xmldatadumps',
        publicdir        => $publicdir,
        otherdir         => '/data/xmldatadumps/public/other',
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
        labhost   => 'labstore1003.eqiad.wmnet',
        publicdir => $publicdir,
        otherdir  => $otherdir,
    }
}
