class dumps::web::html(
    $datadir = undef,
    $publicdir = undef,
    $otherdir = undef,
    $webuser = undef,
    $webgroup = undef,
) {
    class {'dumps::web::dirs':
        datadir          => $datadir,
        publicdir        => $publicdir,
        otherdir         => $otherdir,
        user             => $webuser,
        group            => $webgroup,
    }

    file { "${publicdir}/dumps.css":
        ensure => 'present',
        path   => "${publicdir}/dumps.css",
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

    file { "${publicdir}/other/analytics/index.html":
        ensure => 'present',
        path   => "${publicdir}/other/analytics/index.html",
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

    file { "${publicdir}/archive/index.html":
        ensure => 'present',
        path   => "${publicdir}/archive/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/archive_index.html',
    }

    file { "${publicdir}/index.html":
        ensure => 'present',
        path   => "${publicdir}/index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/public_index.html',
    }

    file { "${publicdir}/mirrors.html":
        ensure => 'present',
        path   => "${publicdir}/mirrors.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/public_mirrors.html',
    }

    file { "${publicdir}/legal.html":
        ensure => 'present',
        path   => "${publicdir}/legal.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/html/legal.html',
    }
}
