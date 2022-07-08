# SPDX-License-Identifier: Apache-2.0
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
    Wmflib::Ensure $ensure = 'present',
    Stdlib::Port   $port   = 8080,
) {
    nginx::site { $title:
        ensure  => $ensure,
        content => template('nginx/status.nginx.erb'),
    }
}
