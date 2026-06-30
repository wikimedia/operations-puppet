# SPDX-License-Identifier: Apache-2.0
# @summary define to generate a known-client rate limits file
# @param conftool_prefix the prefix to use for conftool
# @param cache_cluster name of cache cluster e.g. upload or text
# @param reload_vcl_opts options for the reload of VCL
define profile::cache::varnish::known_client_rate_limits_file (
    String $conftool_prefix,
    Enum['text', 'upload'] $cache_cluster,
    String $reload_vcl_opts,
) {
    $safe_title = $title.regsubst('\W', '-', 'G')
    confd::file { "/etc/varnish/${safe_title}.inc.vcl":
        ensure     => present,
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
        watch_keys => ['/request-known-clients'],
        content    => template('profile/cache/varnish-frontend-known-client-rate-limits.hp.vcl.tpl.erb'),
        prefix     => $conftool_prefix;
    }
    confd::file { "/etc/varnish/${safe_title}.hp.incl.vcl":
        ensure     => absent,
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
        watch_keys => ["/request-varnish-known-client-ratelimits/${cache_cluster}"],
        prefix     => $conftool_prefix;
    }
}
