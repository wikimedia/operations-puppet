class protoproxy::service {
  service { ['nginx']:
    ensure => running,
    enable => true,
  }
}
