# == Class: graphoid
#
# This class installs and configures graphoid, a node.js service that
# converts a graph definition into a PNG image
#
# === Parameters
#
# [*domains*]
#   The list of enabled domains. Default: []
#
# [*domain_map*]
#   The domain-to-domain alias map. Default: {}
#
# [*protocol*]
#   The default protocol to use when connecting to the MW api. Default: https
#
# [*timeout*]
#   The timeout (in ms) for requests. Default: 5000
#
# [*allowed_domains*]
#   The protocol-to-list-of-domains map. Default: {}
#   The protocols include http, https, as well as some custom graph-specific protocols.
#   See https://www.mediawiki.org/wiki/Extension:Graph?venotify=restored#External_data
#
class graphoid(
    $domains    = [],
    $domain_map = {},
    $protocol   = 'https',
    $timeout    = 5000,
    $allowed_domains = {},
) {

    if os_version('debian >= jessie') {
        $libjpeg62 = 'libjpeg62-turbo'
    } else {
        $libjpeg62 = 'libjpeg62'
    }

    service::packages { 'graphoid':
        pkgs     => ['libcairo2', 'libgif4', 'libjpeg62-turbo', 'libpango1.0-0'],
        dev_pkgs => ['libcairo2-dev', 'libgif-dev', 'libpango1.0-dev',
        'libjpeg62-turbo-dev'],
    }

    service::node { 'graphoid':
        port            => 19000,
        config          => {
            domains         => $domains,
            domainMap       => $domain_map,
            defaultProtocol => $protocol,
            timeout         => $timeout,
            allowedDomains  => $allowed_domains,
        },
        has_spec        => true,
        healthcheck_url => '',
        require         => Service::Packages['graphoid'],
    }

}
