# planet RSS feed aggregator 3.0 (rawdog)
# this sets up multiple Planet Wikimedia feed aggregators
# see https://meta.wikimedia.org/wiki/Planet_Wikimedia
# http://planet.wikimedia.org/
#
# see role/planet.pp for language and translation config
#
# required parameters:
#
# $domain_name - domain name used in Apache/SSL configs
#   example "planet.wikimedia.org
# $languages - a hash with languages and UI translations
#   see the role class for this
# $meta_link - https:// link
#   example: meta.wikimedia.org/wiki/Planet_Wikimedia
# $http_proxy - set proxy to be used for downloading feeds
#   example: http://url-downloader.${::site}.wikimedia.org:8080
class planet (
    Stdlib::Fqdn $domain_name,
    Hash $languages,
    Stdlib::Httpsurl $meta_link,
    Stdlib::Httpurl $http_proxy,
) {

    # things done once for all planet per languages
    include ::planet::packages
    include ::planet::dirs
    include ::planet::user

    class { '::planet::index_site':
        domain_name => $domain_name,
        meta_link   => $meta_link,
    }

    $logo_file = '/var/www/planet/planet-wm2.png'

    # TODO change this to be one per language
    file { $logo_file:
        source => 'puppet:///modules/planet/theme/images/planet-wm2.png',
        owner  => 'planet',
        group  => 'www-data',
    }

    # things done per each language version
    # we iterate over the keys of the hash
    # which includes language names and translations
    $languages_keys = keys($languages)
    # creates one document root per language
    planet::docroot { $languages_keys: }

    # creates one Apache VirtualHost per language
    planet::apachesite { $languages_keys:
        domain_name => $domain_name,
    }

    # creates one RSS/Atom feed config per language
    planet::config { $languages_keys:
        domain_name => $domain_name,
    }

    # creates one cron for updates per language
    planet::cronjob { $languages_keys: }

    # creates one planet theme (css/logo) per language
    planet::theme { $languages_keys: }

    # creates RSS dir and plugin per language
    planet::rawdogplugin { $languages_keys: }
}

