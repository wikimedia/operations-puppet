class ganglia::monitor::config($gmond_port, $cname, $aggregator_hosts, $override_hostname=undef) {
    require ganglia::monitor::packages

    $aggregator = false

    file { '/etc/ganglia/gmond.conf':
        mode    => '0444',
        content => template("${module_name}/gmond.conf.erb"),
        notify  => Service['ganglia-monitor'],
    }
}
