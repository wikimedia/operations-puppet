# == Class: cxserver
#
# cxserver is a node.js backend for the Content Translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*apertium*]
#   Url to Apertium service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*youdao_api_key*]
#   API key for Youdao service.
# [*jwt_secret*]
#   JWT secret token.
class cxserver(
    $apertium = "http://apertium.svc.${::site}.wmnet:2737",
    $yandex_api_key = undef,
    $youdao_api_key = undef,
    $jwt_secret = undef,
) {

    service::node { 'cxserver':
        port              => 8080,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            jwt_token    => $jwt_secret,
            apertium_uri => $apertium,
            yandex_key   => $yandex_api_key,
            youdao_key   => $youdao_api_key,
        },
    }
}
