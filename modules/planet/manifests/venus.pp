# http://planet.wikimedia.org/ - new planet (planet-venus)
# http://intertwingly.net/code/venus/

class planet::venus( $planet_domain_name, $planet_languages ) {

  $planet_languages_keys = keys($planet_languages)

  # things done once
  include planet::webserver,
          planet::packages,
          planet::locales,
          planet::dirs,
          planet::user,
          planet::index_site

  # things done per each language version
  planet::config { $planet_languages_keys: }
  planet::docroot { $planet_languages_keys: }
  planet::cronjob { $planet_languages_keys: }
  planet::theme { $planet_languages_keys: }
  planet::apache_site{ $planet_languages_keys: }

}
