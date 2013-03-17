# planet RSS feed aggregator 2.0 (planet-venus)

class planet {

  system_role { 'planet': description => 'Planet (venus) weblog aggregator' }

  # be flexible about labs vs. prod
  case $::realm {
    labs: {
      $planet_domain_name = 'wmflabs.org'
    }
    production: {
      $planet_domain_name = 'wikimedia.org'
    }
    default: {
      fail('unknown realm, should be labs or production')
    }
  }

  # set language versions and translations in languages.pp
  include planet::languages

  # the actual planet-venus class doing all the rest
  class {'planet::venus':
    planet_domain_name => $planet_domain_name,
    planet_languages => $languages::planet_languages,
  }

}

