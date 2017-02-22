# == Define: prometheus::class_config
#
# Generate prometheus targets configuration for all servers including a specified class.
# Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:    The output file where to write the result.
# $class_name:    Class name to search.
# $site:    The site to use.
# $port:    The port to use for the target.
# $labels:  Labels to attach to every host. 'Cluster' will be added automagically as well
# $class_parameters: hash of parameters for the class
#
# == Example
#
#  Configuration for varnish_exporter for maps, running on the frontend varnish
#  instance.
#
#  prometheus::class_config{ "redis_${::site}:
#      dest    => "${targets_path}/redis_${::site}.yaml",
#      site    => $::site,
#      class_name => 'redis',
#      port    => '9331',
#  }

define prometheus::class_config(
    $dest,
    $site,
    $class_name,
    $port,
    $labels = {},
    $class_parameters = {},
) {
    validate_string($dest)
    validate_string($site)
    validate_string($class_name)
    validate_re($port, '^[0-9]+$')
    validate_hash($labels)
    validate_hash($class_parameters)

    if empty($class_parameters) {
        $param_query = ''
     } else {
        $param_query = inline_template('{<%=  @class_parameters.map{ |k,v| "#{k} = \"#{v}\"" }.join(", ") %>}')
    }

    $query = "Class['${class_name}']${param_query}"
    $servers = keys(query_resources(false, $query, true))
    $site_clusters = get_clusters({'site' => $site})

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/class_config.erb'),
    }
}
