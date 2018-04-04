# == Define: prometheus::jmx_exporter_config
#
# Generate prometheus targets configuration for all nodes belonging to $class
# and are defining prometheus::jmx_exporter_instance.
# Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:                The output file where to write the result.
# $class_name:          Class name to search.
# $site:                The site to use.
# $jmx_instance_prefix: jmx instance prefix to target only specific jmx instances.
#                       Useful on shared environments where $class_name may pick
#                       up all of the jmx instances running.
# $labels:              Labels to attach to every host. 'Cluster' will be added automagically as well

define prometheus::jmx_exporter_config(
    $dest,
    $class_name,
    $site,
    $jmx_instance_prefix = '',
    $labels = {},
) {
    validate_string($dest)
    validate_string($site)
    validate_hash($labels)

    $resources = query_resources(
                  "Class[\"${class_name}\"]",
                  "Prometheus::Jmx_exporter_instance[~\"${jmx_instance_prefix}.*\"]",
                  true)
    $site_clusters = get_clusters({'site' => $site})

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/jmx_exporter_config.erb'),
    }
}
