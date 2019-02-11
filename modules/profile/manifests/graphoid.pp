# == Class: profile::graphoid
#
# This class installs and configures graphoid, a node.js service that
# converts a graph definition into a PNG image
#
# === Parameters
#
# [*allowed_domains*]
#   The protocol-to-list-of-domains map. Default: {}
#   The protocols include http, https, as well as some custom graph-specific protocols.
#   See https://www.mediawiki.org/wiki/Extension:Graph?venotify=restored#External_data#
# [*headers*]
#   A map of headers that will be sent with each reply. Could be used for caching, etc. Default: false
#
# [*error_headers*]
#   A map of headers that will be sent with each reply in case of an error. If not set, above headers will be used. Default: false
#
class profile::graphoid(
    $allowed_domains = hiera('profile::graphoid::allowed_domains'),
    $headers       = hiera('profile::graphoid::headers'),
    $error_headers = hiera('profile::graphoid::error_headers'),
) {
    $domain_map    = {}
    $timeout       = 5000

    require ::mediawiki::packages::fonts

    service::packages { 'graphoid':
        pkgs     => ['libcairo2', 'libgif4', 'libjpeg62-turbo', 'libpango1.0-0'],
        dev_pkgs => ['libcairo2-dev', 'libgif-dev', 'libpango1.0-dev', 'libjpeg62-turbo-dev'],
    }


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
