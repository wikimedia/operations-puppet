# == Define: nginx::status_site
#
# Provisions an Nginx site that serves local clients server stats,
# using the stub_status module.
#
# See <http://wiki.nginx.org/HttpStubStatusModule> for details.
#
# === Parameters
#
# [*port*]
#   Port to listen on. Defaults to 8080.
#
define nginx::status_site(
    $ensure = present,
    $port   = 8080,
) {
    nginx::site { 'status':
        ensure  => $ensure,
        content => template('nginx/status.nginx.erb'),
    }
}
