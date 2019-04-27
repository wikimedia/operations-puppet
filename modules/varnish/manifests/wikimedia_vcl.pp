define varnish::wikimedia_vcl(
    $varnish_testing = false,
    $template_path = '',
    $vcl_config = {},
    $cache_route = '',
    $backend_caches = {},
    $vcl = '',
    $inst = '',
    $generate_extra_vcl = false,
    $app_directors={},
    $app_def_be_opts={},
    $is_separate_vcl=false,
    $wikimedia_nets=[],
    $wikimedia_trust=[],
) {
    if $varnish_testing  {
        $dynamic_backend_caches = false
        $netmapper_dir = '/usr/share/varnish/tests'
    } else {
        $dynamic_backend_caches = hiera('varnish::dynamic_backend_caches', true)
        $netmapper_dir = '/var/netmapper'
    }

    # Hieradata switch to shut users out of a DC/cluster. T129424
    $traffic_shutdown = hiera('cache::traffic_shutdown', false)

    $varnish_version = $::varnish::common::varnish_version

    if $generate_extra_vcl {
        $extra_vcl_name = regsubst($title, '^([^ ]+) .*$', '\1')
        $extra_vcl_filename = "/etc/varnish/${extra_vcl_name}.inc.vcl"
        if !defined(File[$extra_vcl_filename]) {
            file { $extra_vcl_filename:
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template("varnish/${extra_vcl_name}.inc.vcl.erb"),
            }
        }
    } else {
        file { $title:
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template($template_path),
            notify  => $notify,
            require => $require,
            before  => $before,
        }
    }
}
