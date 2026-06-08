function varnish::reload_vcl_opts(Integer $probe_ms, Array $separate_vcl, String $instance_name, String $vcl) >> String {
    # T157430 - vcl reloads should delay between load and use for the whole
    # probe window to avoid possibility of spurious spurious 400 when execuing
    # vcl.use.
    $vcl_reload_delay_s = 5

    # Build $reload_vcl_opts
    $separate_vcl_filenames = $separate_vcl.map |$vcl_name| { "/etc/varnish/wikimedia_${vcl_name}.vcl" }

    if (size($separate_vcl_filenames) > 0) {
        $separate_vcl_string = sprintf(' -s %s', join($separate_vcl_filenames, ' '))
    }
    else {
        $separate_vcl_string = ''
    }

    if $instance_name == '' {
        $instance_opt = ''
    } else {
        $instance_opt = "-n ${instance_name}"
    }

    "${instance_opt} -f /etc/varnish/wikimedia_${vcl}.vcl -d ${vcl_reload_delay_s} -a${separate_vcl_string}"
}
