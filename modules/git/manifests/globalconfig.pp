class git::globalconfig {
  file { '/etc/gitconfig.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    recurse => true,
    purge   => true,
  }

  file { '/etc/gitconfig':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/git/system-gitconfig',
  }
}
