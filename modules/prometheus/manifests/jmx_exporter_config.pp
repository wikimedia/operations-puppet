# == Define: prometheus::jmx_exporter_config
#
# Generate prometheus targets configuration for all nodes belonging to $class
# and are defining prometheus::jmx_exporter_instance.
# Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:       The output file where to write the result.
# $class_name: Class name to search.
# $site:       The site to use.
# $labels:     Labels to attach to every host. 'Cluster' will be added automagically as well

define prometheus::jmx_exporter_config(
    $dest,
    $class_name,
    $site,
    $labels = {},
) {
    validate_string($dest)
    validate_string($site)
    validate_hash($labels)

    $resources = query_resources(
                  "Class[\"${class_name}\"]",
                  'Prometheus::Jmx_exporter_instance',
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
