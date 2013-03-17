# packages for a planet-venus server

class planet::packages {

  # the main package
  # prefer to update this manually
  package { 'planet-venus':
    ensure => present;
  }

  # locales are important for planet
  # they can be auto-updated though
  package { 'locales':
    ensure => latest;
  }

}
