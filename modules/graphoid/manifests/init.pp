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
# [*timeout*]
#   The timeout (in ms) for requests. Default: 5000
#
class graphoid(
    $domains    = [],
    $domain_map = {},
    $timeout    = 5000,
) {

    if os_version('debian >= jessie') {
        $libjpeg62 = 'libjpeg62-turbo'
    else {  
        $libjpeg62 = 'libjpeg62'
    } 

    require_package('libcairo2', 'libgif4', $libjpeg62, 'libpango1.0-0')

    service::node { 'graphoid':
        port    => 19000,
        config  => template('graphoid/config.yaml.erb'),
        require => Package['libcairo2', 'libgif4', $libjpeg62, 'libpango1.0-0'],
    }

}

