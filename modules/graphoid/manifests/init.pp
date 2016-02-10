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

    $packages = ['libcairo2', 'libgif4', $libjpeg62, 'libpango1.0-0']
    require_package($packages)

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
        require         => Package[$packages],
    }

}
