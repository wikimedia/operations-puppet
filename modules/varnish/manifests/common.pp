class varnish::common {
  require varnish::packages

  # Tune kernel settings
  include generic::sysctl::high-http-performance

  # Mount /var/lib/varnish as tmpfs to avoid Linux flushing mlocked
  # shm memory to disk
  mount { '/var/lib/varnish':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'noatime,defaults,size=512M',
    pass    => 0,
    dump    => 0,
    require => Class['varnish::packages'],
  }

  file { '/usr/share/varnish/reload-vcl':
    source => 'puppet:///modules/varnish/reload-vcl',
    mode   => '0555';
  }
}
