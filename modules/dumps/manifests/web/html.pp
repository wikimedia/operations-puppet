class dumps::web::html(
    $datadir = undef,
    $xmldumpsdir = undef,
    $otherdir = undef,
    $webuser = undef,
    $webgroup = undef,
) {
    class {'dumps::web::dirs':
        datadir     => $datadir,
        xmldumpsdir => $xmldumpsdir,
        otherdir    => $otherdir,
        user        => $webuser,
        group       => $webgroup,
    }

    file { "${xmldumpsdir}/dumps.css":
        ensure => 'present',
        path   => "${xmldumpsdir}/dumps.css",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/dumps.css',
    }

    file { "${otherdir}/index.html":
        ensure => 'present',
        path   => "${otherdir}/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/other_index.html',
    }

    file { "${otherdir}/pagecounts-ez/index.html":
        ensure => 'present',
        path   => "${otherdir}/pagecounts-ez/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/pagecounts-ez_index.html',
    }

    file { "${xmldumpsdir}/other/analytics/index.html":
        ensure => 'present',
        path   => "${xmldumpsdir}/other/analytics/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/analytics_index.html',
    }

    file { "${otherdir}/poty/index.html":
        ensure => 'present',
        path   => "${otherdir}/poty/index.html",
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
