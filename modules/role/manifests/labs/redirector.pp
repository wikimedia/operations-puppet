# Provision nginx as a http redirector
#
# Installs nginx and configures multiple named vhosts which each map to a single
# 301 status redirect. Can be used to setup permanent redirects from Labs web
# proxies to new locations such as Tool Lab tools.
#
# [*default_url*]
#   Default URL to redirect unconfigured Hosts to. Will emit a 302 redirect
#   rathter than a 301.
#
# [*redirects*]
#   Hash of (Host, target URL) values
#
# filtertags: labs-project-redirects
class role::labs::redirector(
    $default_url,
    $redirects,
) {
    class { '::nginx':
        variant => 'light',
    }
    nginx::site { 'redirect':
        content => template('role/labs/redirector/nginx.conf.erb'),
    }
}
