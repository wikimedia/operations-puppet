# == Class: cxserver
#
# cxserver is a node.js backend for the content translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*base_path*]
#   Path to the cxserver code.
# [*node_path*]
#   Path to the node modules cxserver depends on.
# [*conf_path*]
#   Where to place the config file. Currently cxserver expects it to be next to
#   Server.js, so you might want to place the config outside the repository and
#   place symlink to this file.
# [*logstash_host*]
#   GELF logging host.
# [*logstash_port*]
#   GELF logging port. Default: 12201
# [*restbase*]
#   Url to Restbase API.
# [*apertium*]
#   Url to Apertium service.
# [*yandex_url*]
#   Url to Yandex service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*proxy*]
#   Proxy URL for cxserver.
# [*registry*]
#   Registry to use for language pairs for Content Translation.
# [*jwt_secret*]
#   JWT secret token
class cxserver(
    $base_path = '/srv/deployment/cxserver/deploy',
    $node_path = '/srv/deployment/cxserver/deploy/node_modules',
    $conf_path = '/srv/deployment/cxserver/deploy/src/config.yaml',
    $logstash_host  = undef,
    $logstash_port  = 12201,
    $restbase = 'https://@lang.wikipedia.org/api/rest_v1/page/html/@title',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $yandex_url = undef,
    $yandex_api_key = undef,
    $proxy = undef,
    $registry = undef,
    $jwt_secret = undef,
) {
    if $registry {
        $ordered_registry = ordered_json($registry)
    }

    service::node { 'cxserver':
        port => 8080,
        config => template('cxserver/config.yaml.erb'),
    }
}
