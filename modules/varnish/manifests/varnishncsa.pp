class varnish::varnishncsa {
  upstart_job { 'varnishncsa':
    install => true
  }
}
