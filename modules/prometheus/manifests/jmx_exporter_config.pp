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
# [*instance_selector*]
#   Regex to select jmx_exporter_instances by title.  Default: .*
#
# [*labels*]
#   Hash of labels to attach to every host. 'cluster' will be added automatically as well.
#
define prometheus::jmx_exporter_config(
    String $dest,
    String $class_name,
    String $instance_selector = '.*',
    Hash   $labels            = {},
) {

    $_class_name = wmflib::resource::capitalize($class_name)
    $pql = @("PQL")
    resources[certname, parameters] {
        type = "Prometheus::Jmx_exporter_instance" and title ~ "${instance_selector}" and
        nodes { resources { type =  "Class" and title = "${_class_name}" } }
        order by parameters
    }
    | PQL
    $resources = wmflib::puppetdb_query($pql)
    $site_clusters = wmflib::get_clusters({'site' => [$::site]})

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/jmx_exporter_config.erb'),
    }
}
