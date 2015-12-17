# == Class: cxserver
#
# cxserver is a node.js backend for the Content Translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*restbase_host*]
#   The host/port where to reach RESTBase
# [*restbase_path*]
#   The URI path to append to *restbase_host*
# [*apertium*]
#   Url to Apertium service.
# [*yandex_url*]
#   Url to Yandex service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*registry*]
#   Registry to use for language pairs for Content Translation.
# [*jwt_secret*]
#   JWT secret token.
class cxserver(
    $restbase_host = 'http://restbase.svc.eqiad.wmnet:7231',
    $restbase_path = '/@lang.wikipedia.org/v1/page/html/@title',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $yandex_url = undef,
    $yandex_api_key = undef,
    $registry = undef,
    $jwt_secret = undef,
) {
    if $registry {
        $ordered_registry = ordered_json($registry)
    }

    $restbase_url = "${restbase_host}${restbase_path}"

    service::node { 'cxserver':
        port   => 8080,
        config => template('cxserver/config.yaml.erb'),
    }
}
