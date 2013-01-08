# vim: set ts=2 sw=2 et :

# MediaWiki configuration specific to labs instances ('beta' project)
class mediawiki_new::labs {

  # /srv is used by git-deploy to publish MediaWiki copies to the Apaches
  # servers. On labs, we want to use /dev/vdb which is mounted as /mnt
  file { '/mnt/srv':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }

  # Provide a symbolic link to match production. Will avoid us headhaches with
  # hardcoded paths in production scripts and configuration files.
  file { '/srv':
    ensure  => link,
    owner   => 'root',
    group   => 'root',
    target  => '/mnt/srv',
    require => File['/mnt/srv'],
  }

}
