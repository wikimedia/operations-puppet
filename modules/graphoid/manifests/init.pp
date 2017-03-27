# == Class: graphoid
#
# This class installs and configures graphoid, a node.js service that
# converts a graph definition into a PNG image
#
# === Parameters
#
# [*allowed_domains*]
#   The protocol-to-list-of-domains map. Default: {}
#   The protocols include http, https, as well as some custom graph-specific protocols.
#   See https://www.mediawiki.org/wiki/Extension:Graph?venotify=restored#External_data
#
# [*domain_map*]
#   The domain-to-domain alias map. Default: {}
#
# [*timeout*]
#   The timeout (in ms) for requests. Default: 5000
#
# [*headers*]
#   A map of headers that will be sent with each reply. Could be used for caching, etc. Default: false
#
# [*error_headers*]
#   A map of headers that will be sent with each reply in case of an error. If not set, above headers will be used. Default: false
#
class graphoid(
    $allowed_domains = {},
    $domain_map    = {},
    $timeout       = 5000,
    $headers       = false,
    $error_headers = false,
) {

    require ::graphoid::packages

    requires_os('debian >= jessie')

    service::node { 'graphoid':
        port            => 19000,
        config          => {
            allowedDomains => $allowed_domains,
            domainMap      => $domain_map,
            timeout        => $timeout,
            headers        => $headers,
            errorHeaders   => $error_headers,
        },
        has_spec        => true,
        healthcheck_url => '',
        deployment      => 'scap3',
    }

}
