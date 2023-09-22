# == Define: prometheus::redis_exporter_config
#
# Generate prometheus targets configuration for all nodes belonging to $class
# and are defining prometheus::redis_exporter.
# Data is gathered using the puppetdb querying functions

# == Parameters
# $dest:       The output file where to write the result.
# $class_name: Class name to search.
# $labels:     Labels to attach to every host. 'Cluster' will be added automagically as well

define prometheus::redis_exporter_config(
    String $dest,
    String $class_name,
    Hash $labels = {},
) {
    $resources = query_resources(
                  "Class[\"${class_name}\"]",
                  'Prometheus::Redis_exporter[~".*"]',
                  true)
    $site_clusters = wmflib::get_clusters({'site' => [$::site]})

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/redis_exporter_config.erb'),
    }
}
