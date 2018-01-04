# planet RSS feed aggregator 2.0 (planet-venus)
# this sets up multiple Planet Wikimedia feed aggregators
# see https://meta.wikimedia.org/wiki/Planet_Wikimedia
# http://planet.wikimedia.org/ - new planet (planet-venus)
#
# see role/planet.pp for language and translation config
#
# required parameters:
#
# $planet_domain_name - domain name used in Apache/SSL configs
#   example "planet.wikimedia.org
# $planet_languages - a hash with languages and UI translations
#   see the role class for this
# $planet_meta_link - a protocol relative link
#   example: meta.wikimedia.org/wiki/Planet_Wikimedia
# $planet_http_proxy - set proxy to be used for downloading feeds
#   example: http://url-downloader.${::site}.wikimedia.org:8080
class planet_httpd (
    $planet_domain_name,
    $planet_languages,
    $planet_meta_link,
    $planet_http_proxy,
) {

    # locales are essential for planet
    # if a new language is added check these too
    include ::locales::extended

    # things done once for all planet per languages
    include ::planet_httpd::packages
    include ::planet_httpd::dirs
    include ::planet_httpd::user
    include ::planet_httpd::index_site

    if os_version('debian >= stretch') {
        $logo_file = '/var/www/planet/planet-wm2.png'
    } else {
        $logo_file = '/usr/share/planet-venus/theme/common/images/planet-wm2.png'
    }

    # TODO change this to be one per language
    file { $logo_file:
        source => 'puppet:///modules/planet_httpd/theme/images/planet-wm2.png',
        owner  => 'planet',
        group  => 'www-data',
    }

    # things done per each language version
    # we iterate over the keys of the hash
    # which includes language names and translations
    $planet_languages_keys = keys($planet_languages)
    # creates one document root per language
    planet_httpd::docroot { $planet_languages_keys: }

    # creates one Apache VirtualHost per language
    planet_httpd::apachesite { $planet_languages_keys: }

    # creates one RSS/Atom feed config per language
    planet_httpd::config { $planet_languages_keys: }

    # creates one cron for updates per language
    planet_httpd::cronjob { $planet_languages_keys: }

    # creates one planet theme (css/logo) per language
    planet_httpd::theme { $planet_languages_keys: }

    if os_version('debian >= stretch') {
      # creates RSS dir and plugin per language
      planet_httpd::rawdogplugin { $planet_languages_keys: }
    }
}

