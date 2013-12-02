class varnish::logging::config {
    file { '/etc/default/varnishncsa':
        source => "puppet:///modules/${module_name}/varnishncsa.default",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
