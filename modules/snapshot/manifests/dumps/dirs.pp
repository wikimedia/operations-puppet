class snapshot::dumps::dirs (
    $user = undef,
    $group = undef,
) {
    $dumpsdir = '/etc/dumps'
    file { $dumpsdir:
      ensure => 'directory',
      path   => $dumpsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $datadir = '/mnt/data/xmldatadumps'
    $apachedir = '/srv/mediawiki'

    file { "${dumpsdir}/confs":
      ensure => 'directory',
      path   => "${dumpsdir}/confs",
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $dblistsdir = "${dumpsdir}/dblists"
    file { "$dblistsdir":
      ensure => 'directory',
      path   => "$dblistsdir",
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

    file { "${dumpsdir}/templs":
      ensure => 'directory',
      path   => "${dumpsdir}/templs",
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


    $scriptsdir = '/srv/dumps'
    file { $scriptsdir:
      ensure => 'directory',
      path   => $scriptsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
}
