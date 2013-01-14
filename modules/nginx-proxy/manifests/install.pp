class nginx-proxy::install {
  package { [ "nginx" ]:
  ensure => present,
  }
}

