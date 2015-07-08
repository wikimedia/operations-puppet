# Writes the actual config file for pybal. Uses the datacenter as title
#
# === Parameters
#
# [*pool_name*]
#   The pool name in pybal's terms
#
# [*cluster*]
#   The cluster we're writing the file for.
#
# [*service*]
#   The service we're writing the file for.
#
define pybal::conf_file (
    $pool_name,
    $cluster,
    $service,
    $basedir = undef,
){
    $dc = $name
    $watch_keys = ["/conftool/v1/pools/${dc}/${cluster}/${service}/"]

    $filepath = $basedir ? {
        undef   => "/etc/pybal/pools/${pool_name}",
        default => "${basedir}/${dc}/${pool_name}"
    }

    confd::file { $filepath:
        watch_keys => $watch_keys,
        content    => template('pybal/host-pool.tmpl.erb'),
        check      => '/usr/local/bin/pybal-eval-check',
        require    => File['/etc/pybal/pools'],
    }
}
