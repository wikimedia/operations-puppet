# == Class: gdash::nginx
#
# Provisions Nginx as reverse-proxy for Gdash running under uWSGI.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server. May contain wildcards.
#   See <http://nginx.org/en/docs/http/server_names.html>.
#   Defaults to '_', which is catch-all.
#
class gdash::nginx(
    $server_name     = '_',
) {
    nginx::site { 'gdash':
        content => template('gdash/gdash.nginx.erb'),
    }
}
