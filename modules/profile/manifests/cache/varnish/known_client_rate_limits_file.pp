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
    # Select the rate limit enabled and value field names associated with this cluster.
    $cluster_limit_field_name = "throttle_requests_${cache_cluster}"
    $cluster_limit_enabled_field_name = "throttle_requests_${cache_cluster}_enabled"
    # Select the default rate limit associated with this cluster. Units are requests per minute.
    # These should be compatible with https://wikitech.wikimedia.org/wiki/Robot_policy.
    # TODO: T403220 - Finalize these limits before enabling rate limiting.
    $default_rate_limit = $cache_cluster ? {
        'text'   => 3000,  # 50 rps on average
        'upload' => 600,   # 10 rps on average
    }
    $safe_title = $title.regsubst('\W', '-', 'G')
    confd::file { "/etc/varnish/${safe_title}.inc.vcl":
        ensure     => present,
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
        watch_keys => ['/request-known-clients'],
        content    => template('profile/cache/varnish-frontend-known-client-rate-limits.vcl.tpl.erb'),
        prefix     => $conftool_prefix;
    }
    confd::file { "/etc/varnish/${safe_title}.hp.incl.vcl":
        ensure     => present,
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
        watch_keys => ["/request-varnish-known-client-ratelimits/${cache_cluster}"],
        content    => template('profile/cache/varnish-frontend-known-client-rate-limits.hp.vcl.tpl.erb'),
        prefix     => $conftool_prefix;
    }
}
