define varnish::setup_filesystem() {
  file { "/srv/${title}":
    ensure => directory,
    owner  => root,
    group  => root,
  }

  mount { "/srv/${title}":
    ensure  => mounted,
    device  => "/dev/${title}",
    fstype  => 'xfs',
    options => 'noatime,nodiratime,nobarrier,logbufs=8',
    require => File["/srv/${title}"],
  }

  file { "/srv/${title}/varnish.persist":
    ensure  => present,
    owner   => root,
    group   => root,
    require => Mount["/srv/${title}"],
  }
}
