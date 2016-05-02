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
# [*no_proxy_list*]
#   List of no_proxy values.
# [*registry*]
#   registry file to use.
class cxserver(
    $restbase_url = "http://restbase.svc.${::rb_site}.wmnet:7231/@lang.wikipedia.org/v1/page/html/@title",
    $apertium = "http://apertium.svc.${::site}.wmnet:2737",
    $yandex_url = undef,
    $yandex_api_key = undef,
    $jwt_secret = undef,
    $no_proxy_list = undef,
    $registry = 'registry.wikimedia.yaml',
) {
    if $no_proxy_list {
        validate_array($no_proxy_list)
    }

    service::node { 'cxserver':
        port            => 8080,
        config          => template('cxserver/config.yaml.erb'),
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
    }
}
