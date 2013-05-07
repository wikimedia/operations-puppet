class protoproxy::package {

  package { ['nginx']:
    ensure => latest;
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => absent;
  }

}
