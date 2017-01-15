class snapshot::dumps::templates {
    include ::snapshot::dumps::dirs
    $templsdir = $snapshot::dumps::dirs::templsdir

    file { "${templsdir}/download-index.html":
        ensure => 'present',
        path   => "${templsdir}/download-index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/download-index.html',
    }
    file { "${templsdir}/dvd.html":
        ensure => 'present',
        path   => "${templsdir}/dvd.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/dvd.html',
    }
    file { "${templsdir}/errormail.txt":
        ensure => 'present',
        path   => "${templsdir}/errormail.txt",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/errormail.txt',
    }
    file { "${templsdir}/feed.xml":
        ensure => 'present',
        path   => "${templsdir}/feed.xml",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/feed.xml',
    }
    file { "${templsdir}/legal.html":
        ensure => 'present',
        path   => "${templsdir}/legal.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/legal.html',
    }
    file { "${templsdir}/progress.html":
        ensure => 'present',
        path   => "${templsdir}/progress.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/progress.html',
    }
    file { "${templsdir}/report.html":
        ensure => 'present',
        path   => "${templsdir}/report.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/templates/report.html',
    }

    $warning = "The files in this directory are maintained by puppet!\n"
    $location = "puppet:///modules/snapshot/dumps/templates\n"

    file { "${templsdir}/README":
        ensure  => 'present',
        path    => "${templsdir}/README",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${warning}${location}",
    }
}
