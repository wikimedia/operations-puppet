class protoproxy::service {
# FIXME require protoproxy::proxy_sites

  service { ['nginx']:
    ensure => running,
    enable => true,
  }
}
