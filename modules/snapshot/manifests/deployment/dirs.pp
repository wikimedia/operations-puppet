class snapshot::deployment::dirs {
    $repodir = '/srv/deployment/dumps/dumps'

    file { "${repodir}/scap":
      ensure => 'directory',
      path   => "${repodir}/scap",
      mode   => '0775',
      owner  => trebuchet,
      group  => wikidev,
    }

    file { "${repodir}/scap/scap.cfg":
      mode   => '0644',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/snapshot/deployment/scap.cfg'
    }

    $target_list = 'snapshot1005.eqiad.wmnet\n'
    file { "${repodir}/scap/dumps_targets":
      mode    => '0644',
      owner   => root,
      group   => root,
      content => $target_list,
    }
}
