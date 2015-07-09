# Writes the actual config file for pybal. Uses the datacenter as title
#
# === Parameters
##
# [*dc*]
#  The datacenter we're creating the file for
#
# [*cluster*]
#   The cluster we're writing the file for.
#
# [*service*]
#   The service we're writing the file for.
#
define pybal::conf_file (
    $cluster,
    $service,
    $dc=$::site
){
    $watch_keys = ["/conftool/v1/pools/${dc}/${cluster}/${service}/"]

    confd::file { $name:
        watch_keys => $watch_keys,
        content    => template('pybal/host-pool.tmpl.erb'),
        check      => '/usr/local/bin/pybal-eval-check',
    }
}
