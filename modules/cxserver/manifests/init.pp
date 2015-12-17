# == Class: cxserver
#
# cxserver is a node.js backend for the Content Translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*restbase_url*]
#   Url to Restbase API.
# [*apertium*]
#   Url to Apertium service.
# [*yandex_url*]
#   Url to Yandex service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*jwt_secret*]
#   JWT secret token.
class cxserver(
    $restbase_url = 'http://restbase.svc.eqiad.wmnet:7231/@lang.wikipedia.org/v1/page/html/@title',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $yandex_url = undef,
    $yandex_api_key = undef,
    $jwt_secret = undef,
) {
    service::node { 'cxserver':
        port   => 8080,
        config => template('cxserver/config.yaml.erb'),
    }
}
