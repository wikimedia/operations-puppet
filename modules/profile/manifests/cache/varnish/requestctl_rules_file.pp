# SPDX-License-Identifier: Apache-2.0
# @summary define to generate a requestctl filters file
# @param cache_cluster name of cache cluster e.g. upload or text
# @param conftool_prefix the prefix to use for conftool
# @param reload_vcl_opts options for the reload of VCL
define profile::cache::varnish::requestctl_rules_file (
    String $conftool_prefix,
    Enum['text', 'upload'] $cache_cluster,
    String $reload_vcl_opts,
) {
    if $title !~ /[a-z_]+/ {
        fail("'${title}' is not a valid scope name for requestctl.")
    }

    $conftool_base_path = "/request-vcl/cache-${cache_cluster}"
    if $title == 'default' {
        $path = '/etc/varnish/requestctl-filters.inc.vcl'
        $conftool_global_path = "${conftool_base_path}/global"
        $conftool_local_path = "${conftool_base_path}/${::site}"
    } else {
        $path = "/etc/varnish/requestctl-filters-${title}.inc.vcl"
        $conftool_global_path = "${conftool_base_path}/${title}-global"
        $conftool_local_path = "${conftool_base_path}/${title}-${::site}"
    }
    # The local scope injected in the template.
    $local_scope = $title
    confd::file { $path:
        ensure     => present,
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
        watch_keys => [$conftool_base_path],
        content    => template('profile/cache/varnish-frontend-requestctl-filters.vcl.tpl.erb'),
        prefix     => $conftool_prefix;
    }
}
