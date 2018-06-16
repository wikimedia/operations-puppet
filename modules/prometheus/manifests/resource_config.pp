# == Define: prometheus::resource_config
#
# Generate prometheus targets configuration for all servers including a specified
# resource definition. Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:    The output file where to write the result.
# $define_name:    Define name to search.
# $site:    The site to use.
# $port_parameter: The parameter of $define_name that contains the port prometheus
#   must contact to collect metrics.
# $labels:  Labels to attach to every host. 'Cluster' will be added automagically as well
#
# == Example
#
#
#  Given a resource running multiple instances on a single host with a prometheus
#  exporter per service such as:
#
#    define prometheus::fizzbuzz_exporter($service_port, $prometheus_port) {
#        ...
#    }
#
#  resource_config can then collect all instances, retrieving the appropriate
#  prometheus port from resource instance, via:
#
#    prometheus::resource_config{ "fizzbuzz_${::site}":
#        dest           => "${targets_path}/fizzbuzz_${::site}.yaml",
#        site           => $::site,
#        define_name    => 'prometheus::fizzbuzz_exporter',
#        port_parameter => 'prometheus_port',
#    }

define prometheus::resource_config(
    String $dest,
    String $define_name,
    String $site,
    String $port_parameter,
    Hash $labels = {},
) {
    $query = "${define_name}[~'.*']"
    $resources = query_resources(false, $query, true)
    $site_clusters = get_clusters({'site' => $site})

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/resource_config.erb'),
    }
}
