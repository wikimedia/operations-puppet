class profile::dumps::web::xmldumps_active {
    class {'::dumps::web::xmldumps_active':
        do_acme          => hiera('do_acme'),
        datadir          => '/data/xmldatadumps',
        publicdir        => '/data/xmldatadumps/public',
        otherdir         => '/data/xmldatadumps/public/other',
        logs_dest        => 'stat1005.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
        htmldumps_server => 'francium.eqiad.wmnet',
        xmldumps_server  => 'dumps.wikimedia.org',
    }
    # copy dumps and other datasets between host(s)
    $primaryserver = 'dataset1001.wikimedia.org'
    $secondaryserver = 'ms1001.wikimedia.org'
    $publicsourceinfo = "source=public,server=${primaryserver},type=primary;source=public,server=${secondaryserver},type=secondary"
    $othersourceinfo = "source=other,server=${primaryserver},type=primary;source=other,server=${secondaryserver},type=secondary"
    class {'::dumps::copying::peers':
      serverinfo => "${publicsourceinfo} ${othersourceinfo}"
    }

    # copy dumps and other datasets to labs
    class {'::dumps::copying::labs':}
}
