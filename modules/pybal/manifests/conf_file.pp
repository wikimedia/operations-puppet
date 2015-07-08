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
    $basedir = undef,
    ){
    $dc = inline_template("<%= @name.split('/')[0] %>")
    $cluster = inline_template("<%= @name.split('/')[1] %>")
    $service = inline_template("<%= @name.split('/')[2] %>")
    $watch_keys = ["/conftool/v1/pools/${name}/"]

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
