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
# class { 'role::google_api_proxy'
#     $instances => {
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
# filtertags: labs-project-google-api-proxy
class role::labs::google_api_proxy (
    $instances,
) {
    create_resources(
        '::external_proxy::instance',
        $instances,
        {
            'acls' => [
                'deny 10.68.21.68; # IP we see if XFF unwrapping did not work',
                'allow 10.68.16.0/21; # All of Labs',
                'allow 127.0.0.1;',
                'deny all;',
            ],
        }
    )
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
