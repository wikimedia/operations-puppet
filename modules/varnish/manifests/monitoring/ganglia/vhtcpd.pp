class varnish::monitoring::ganglia::vhtcpd() {
    file {
        "/usr/lib/ganglia/python_modules/vhtcpd.py":
            source => "puppet:///modules/${module_name}/ganglia/ganglia-vhtcpd.py",
            notify => Service['gmond'];

        "/etc/ganglia/conf.d/vhtcpd.pyconf":
            owner => root,
            group => root,
            mode => 0444,
            content => template("${module_name}/ganglia/vhtcpd.pyconf.erb"),
            notify => Service['gmond'];
    }
}
