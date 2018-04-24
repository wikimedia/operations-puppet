# == Define: prometheus::jmx_exporter_config
#
# Generate prometheus targets configuration for all nodes belonging to $class
# and are defining prometheus::jmx_exporter_instance.
# Data is gathered using the puppetdb querying functions

# == Parameters
# [*dest*]
#   Path to jmx exporter config file to render.
#
# [*class_name*]
#   Class name to search.  All nodes with this class declared will be searched
#   for jmx_exporter_instance titles that match $instance_selector.
#
# [*site*]
#   The site to use.
#
# [*instance_selector*]
#   Regex to select jmx_exporter_instances by title.  Default: .*
#
# [*labels*]
#   Hash of labels to attach to every host. 'cluster' will be added automatically as well.
#
define prometheus::jmx_exporter_config(
    $dest,
    $class_name,
    $site,
    $instance_selector = '.*',
    $labels            = {},
) {
    validate_string($dest)
    validate_string($site)
    validate_hash($labels)

    $resources = query_resources(
                  "Class[\"${class_name}\"]",
                  "Prometheus::Jmx_exporter_instance[~\"${instance_selector}\"]",
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
