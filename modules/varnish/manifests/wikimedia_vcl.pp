# @summary resource to create a vcl file
# @param varnish_testing indicate if this is a testing environment
# @param vcl_config A hash if vcl config
# @param backend_caches list of backend caches
# @param backend_options hash of backend configs
# @param dynamic_backend_caches set to true if dynamic backend caches
# @param generate_extra_vcl set to true to generate extra vcl
# @param is_separate_vcl
# @param etcd_filters pull in dynamic rules from etcd
# @param ip_reputation if true, load the ip reputation maps.
# @param wikimedia_nets wikimedia owned networks
# @param wikimedia_trust wikimedia owned trusted
# @param wikimedia_domains wikimedia production owned domains
# @param wmcs_domains wikimedia cloud services owned domains
# @param template_path path t the template
# @param vcl name of vcl include
define varnish::wikimedia_vcl(
    Boolean             $varnish_testing        = false,
    Hash                $vcl_config             = {},
    Array               $backend_caches         = [],
    Hash                $backend_options        = {},
    Boolean             $dynamic_backend_caches = true,
    Boolean             $generate_extra_vcl     = false,
    Boolean             $is_separate_vcl        = false,
    Boolean             $etcd_filters           = false,
    Boolean             $ip_reputation          = false,
    Array               $wikimedia_nets         = [],
    Array               $wikimedia_trust        = [],
    Array[Stdlib::Fqdn] $wikimedia_domains      = [],
    Array[Stdlib::Fqdn] $wmcs_domains           = [],
    Optional[String]    $template_path          = undef,
    Optional[String]    $vcl                    = undef,
    Stdlib::Unixpath    $privileged_uds         = '/run/varnish-privileged.socket',
) {
    if !$generate_extra_vcl and $template_path == undef {
        fail('must provide template_path unless generate_extra_vcl true')
    }
    if $varnish_testing  {
        $netmapper_dir = '/usr/share/varnish/tests'
        $vcl_ip = '10.128.0.129'
    } else {
        $netmapper_dir = '/var/netmapper'
        $vcl_ip = $facts['ipaddress']
    }

    # Hieradata switch to shut users out of a DC/cluster. T129424
    $traffic_shutdown = lookup('cache::traffic_shutdown', {'default_value' => false})
    $wikimedia_domains_regex = $wikimedia_domains.regexpescape.join('|')
    $wmcs_domains_regex = $wmcs_domains.regexpescape.join('|')

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
        }
    }
}
