class dataset::html(
    $public       = true,
    $other        = true,
    $archive      = true,
    $poty         = true,
    $pagecounts_ez = true
    ) {

    include dataset::dirs

    if ($other) {
        file { "${dataset::dirs::otherdir}/index.html":
            ensure => 'present',
            path   => "${dataset::dirs::otherdir}/index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/other_index.html',
        }
    }
    if ($pagecounts_ez) {
        file { "${dataset::dirs::otherdir}/pagecounts-ez/index.html":
            ensure => 'present',
            path   => "${dataset::dirs::otherdir}/pagecounts-ez/index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/pagecounts-ez_index.html',
        }
    }
    if ($poty) {
       file { "${dataset::dirs::otherdir}/poty/index.html":
           ensure => 'present',
           path   => "${dataset::dirs::otherdir}/poty/index.html",
           mode   => '0644',
           owner  => 'root',
           group  => 'root',
           source => 'puppet:///modules/dataset/html/poty_index.html',
       }
    }
    if ($archive) {
        file { "${dataset::dirs::publicdir}/archive/index.html":
            ensure => 'present',
            path   => "${dataset::dirs::publicdir}/archive/index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/archive_index.html',
        }
    }
    if ($public) {
        file { "${dataset::dirs::publicdir}/index.html":
            ensure => 'present',
            path   => "${dataset::dirs::publicdir}/index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/public_index.html',
        }

        file { "${dataset::dirs::publicdir}/mirrors.html":
            ensure => 'present',
            path   => "${dataset::dirs::publicdir}/mirrors.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/public_mirrors.html',
        }

        file { "${dataset::dirs::publicdir}/legal.html":
            ensure => 'present',
            path   => "${dataset::dirs::publicdir}/legal.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/dataset/html/legal.html',
        }
    }
}
