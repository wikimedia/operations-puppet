class package-builder::defaults {

  include packages

  File { mode => 0444 }

  file { '/etc/devscripts.conf':
      content => template('misc/devscripts.conf.erb'),
  }
  file { '/etc/git-buildpackage/gbp.conf':
      require => Package['git-buildpackage'],
      content => template('misc/gbp.conf.erb'),
  }
  file { '/etc/dupload.conf':
      require => Package['dupload'],
      content => template('misc/dupload.conf.erb'),
  }

}
