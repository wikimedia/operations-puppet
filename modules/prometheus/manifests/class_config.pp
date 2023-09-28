# == Define: prometheus::class_config
#
# Generate prometheus targets configuration for all servers including a specified class.
# Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:    The output file where to write the result.
# $class_name:    Class name to search.
# $port:    The port to use for the target.
# $labels:  Labels to attach to every host. 'Cluster' will be added automagically as well
# $class_parameters: hash of parameters for the class
# $hostnames_only: Split on first dot, keeping only the hostname. Defaults to true.
#
# == Example
#
#  Configuration for varnish_exporter for maps, running on the frontend varnish
#  instance.
#
#  prometheus::class_config{ "redis_${::site}:
#      dest    => "${targets_path}/redis_${::site}.yaml",
#      class_name => 'redis',
#      port    => '9331',
#  }

define prometheus::class_config(
    String $dest,
    String $class_name,
    Stdlib::Port $port,
    Hash $labels = {},
    Hash $class_parameters = {},
    Boolean $hostnames_only = true,
    Wmflib::Ensure $ensure = present,
) {
    $_class_name = wmflib::resource::capitalize($class_name)
    $parameters_query = $class_parameters.map |$k, $v| {
        $_v = $v ? {
            String  => "\"${v}\"",
            default => $v,
        }
        "parameters.${k} = ${_v}"
    }.join(' and ')
    $_parameters_query = $class_parameters.empty.bool2str('',"and ${parameters_query}")
    $pql = @("PQL")
    resources[certname] {
        type = "Class" and title = "${_class_name}"
        ${_parameters_query}
        order by certname
    }
    | PQL
    $servers = wmflib::puppetdb_query($pql).map  |$x| { $x['certname'] }
    $site_clusters = wmflib::get_clusters({'site' => [$::site]})

    file { $dest:
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/class_config.erb'),
    }
}
