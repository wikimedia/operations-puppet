# == Class: cxserver
#
# cxserver is a node.js backend for the content translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*restbase*]
#   Url to Restbase API.
# [*apertium*]
#   Url to Apertium service.
# [*yandex_url*]
#   Url to Yandex service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*registry*]
#   Registry to use for language pairs for Content Translation.
# [*jwt_secret*]
#   JWT secret token
class cxserver(
    $restbase = 'http://restbase.svc.eqiad.wmnet:7231/@lang.wikipedia.org/v1/page/html/@title',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $yandex_url = undef,
    $yandex_api_key = undef,
    $registry = undef,
    $jwt_secret = undef,
) {
    if $registry {
        $ordered_registry = ordered_json($registry)
    }

    service::node { 'cxserver':
        port => 8080,
        config => template('cxserver/config.prod.yaml.erb'),
    }
}
