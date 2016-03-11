class snapshot::dirs {
    $dumpsdir = '/srv/dumps'
    $datadir = '/mnt/data/xmldatadumps'
    $apachedir = '/srv/mediawiki'

    file { $dumpsdir:
        ensure => 'directory',
        path   => $dumpsdir,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { "${dumpsdir}/confs":
      ensure => 'directory',
      path   => "${dumpsdir}/confs",
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    file { "${dumpsdir}/dblists":
      ensure => 'directory',
      path   => "${dumpsdir}/dblists",
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    file { "${dumpsdir}/stages":
      ensure => 'directory',
      path   => "${dumpsdir}/stages",
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    file { "${dumpsdir}/cache":
      ensure => 'directory',
      path   => "${dumpsdir}/cache",
      mode   => '0755',
      owner  => 'datasets',
      group  => 'root',
    }

    file { "${snapshot::dirs::dumpsdir}/templs":
      ensure => 'directory',
      path   => "${snapshot::dirs::dumpsdir}/templs",
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $addschangesdir = '/srv/addschanges'

    file { $addschangesdir:
        ensure => 'directory',
        path   => $addschangesdir,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    $wikiqueriesdir = '/srv/wikiqueries'

    file { $wikiqueriesdir:
        ensure => 'directory',
        path   => $wikiqueriesdir,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

}
