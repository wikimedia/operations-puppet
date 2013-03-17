# packages for a planet-venus server

class planet::packages {

  package { 'planet-venus':
    ensure => present;
  }

}
