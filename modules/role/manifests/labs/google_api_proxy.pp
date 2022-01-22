# == Class: role::labs::google_api_proxy
#
# Provision nginx reverse proxy vhosts for accessing Google API endpoints from
# inside Labs via a fixed IP address.
#
# == Parameters:
# [*instances*]
#   A hash mapping vhost names to external_proxy::instance parameters.
#
# == Usage
# class { 'role::labs::google_api_proxy'
#     instances => {
#         'google-api-proxy.wmflabs.org' => {
#             'proxied' => 'https://www.googleapis.com',
#             'default' => true,
#         },
#         'googlevision-api-proxy.wmflabs.org' => {
#             'proxied' => 'https://vision.googleapis.com',
#         },
#     },
# }
#
class role::labs::google_api_proxy (
    $instances,
) {
    class { 'profile::wmcs::google_api_proxy':
        instances => $instances,
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
