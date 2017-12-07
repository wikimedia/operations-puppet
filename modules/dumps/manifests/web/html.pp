class dumps::web::html(
    $datadir = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
    $webuser = undef,
    $webgroup = undef,
) {
    class {'dumps::web::dirs':
        datadir         => $datadir,
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
        user            => $webuser,
        group           => $webgroup,
    }

    file { "${xmldumpsdir}/dumps.css":
        ensure => 'present',
        path   => "${xmldumpsdir}/dumps.css",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/dumps.css',
    }

    file { "${miscdatasetsdir}/index.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/other_index.html',
    }

    file { "${miscdatasetsdir}/pagecounts-ez/index.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/pagecounts-ez/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/pagecounts-ez_index.html',
    }

    file { "${miscdatasetsdir}/analytics/index.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/analytics/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/analytics_index.html',
    }

    file { "${miscdatasetsdir}/pageviews/readme.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/pageviews/readme.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/pageviews_readme.html',
    }

    file { "${miscdatasetsdir}/unique_devices/readme.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/unique_devices/readme.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/unique_devices_readme.html',
    }

    file { "${miscdatasetsdir}/mediacounts/readme.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/mediacounts/readme.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/mediacounts_readme.html',
    }

    file { "${miscdatasetsdir}/clickstream/readme.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/clickstream/readme.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/clickstream_readme.html',
    }


    file { "${miscdatasetsdir}/poty/index.html":
        ensure => 'present',
        path   => "${miscdatasetsdir}/poty/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/poty_index.html',
    }

    file { "${xmldumpsdir}/archive/index.html":
        ensure => 'present',
        path   => "${xmldumpsdir}/archive/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/archive_index.html',
    }

    file { "${xmldumpsdir}/index.html":
        ensure => 'present',
        path   => "${xmldumpsdir}/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/public_index.html',
    }

    file { "${xmldumpsdir}/mirrors.html":
        ensure => 'present',
        path   => "${xmldumpsdir}/mirrors.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/public_mirrors.html',
    }

    file { "${xmldumpsdir}/legal.html":
        ensure => 'present',
        path   => "${xmldumpsdir}/legal.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/legal.html',
    }
}
