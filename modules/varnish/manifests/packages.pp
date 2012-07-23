class varnish::packages($version='installed') {
  package { [ 'varnish', 'libvarnishapi1', 'varnish-dbg' ]:
    ensure => $version;
  }

  package { 'libworking-daemon-perl':
    ensure => present;
  }
}
