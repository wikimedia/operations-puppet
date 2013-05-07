# Definition: protoproxy::instance
#
# This class creates a Nginx installation.
#
# FIXME document parameters
#
# Parameters:
#  - $proxy_addresses
#  - $proxy_addresses
#  - $proxy_server_name
#  - $proxy_server_cert_name
#  - $proxy_backend
#  - $enabled
#  - $proxy_listen_flags
#  - $proxy_port
#  - $ipv6_enabled
#  - $ssl_backend
#
# Actions:
#  Install nginx package and creates a configuration out of a template.
#
# Requires:
# nginx_site definition and the nginx package
#
# Example usage:
#
# See wikimedia role::protoproxy
define protoproxy::instance(
  $proxy_addresses,
  $proxy_server_name,
  $proxy_server_cert_name,
  $proxy_backend,
  $enabled=false,
  $proxy_listen_flags='',
  $proxy_port='80',
  $ipv6_enabled=false,
  $ssl_backend={},
) {

  nginx_site { $name:
      enable   => $enabled,
      template => 'proxy',
      install  => 'template',
      require  => Package['nginx'],
  }

}
