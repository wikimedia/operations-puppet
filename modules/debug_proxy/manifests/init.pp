# == Class: debug_proxy
#
# Transparent proxy which passes requests to a set of un-pooled
# application servers that are reserved for debugging, based on
# the value of the X-Wikimedia-Debug HTTP header.
#
# === Parameters
#
# [*backend_regexp*]
#   If the value of X-Wikimedia-Debug matches this regular expression,
#   it will be used as the backend address, verbatim.
#
# [*backend_aliases*]
#   If the value of X-Wikimedia-Debug is equal to a defined alias,
#   the alias's target will be used as the backend address.
#
# [*resolver*]
#   Value to set as Nginx's 'resolver'.
#   See <http://nginx.org/en/docs/http/ngx_http_core_module.html#resolver>
#
# === Examples
#
# Allow requests to select mw1017 / mw1018 / mw1019 explicitly,
# and map 'X-Wikimedia-Debug: profile' to mw1020:
#
#  class { '::debug_proxy':
#      backend_regexp  => '^mw101[789]',
#      backend_aliases => { 'profile' => 'mw1020.eqiad.wmnet' },
#  }
#
class debug_proxy(
    $backend_regexp,
    $backend_aliases,
    $resolver,
) {
    require_package('libnginx-mod-http-lua')
    nginx::site { 'debug_proxy':
        content => template('debug_proxy/debug_proxy.nginx.erb'),
        notify  => Service['nginx'],
    }

    base::service_auto_restart { 'nginx': }

    # T209709
    nginx::status_site { 'debug_proxy': }
}
