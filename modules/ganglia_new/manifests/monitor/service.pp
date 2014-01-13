class ganglia_new::monitor::service() {
    Class[ganglia_new::monitor::config] -> Class[ganglia_new::monitor::service]

    file { '/etc/init/ganglia-monitor.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/upstart/ganglia-monitor.conf",
    }

    generic::upstart_job { 'ganglia-monitor': }

    service { 'ganglia-monitor':
        ensure   => running,
        require  => File['/etc/init/ganglia-monitor.conf'],
        alias    => 'gmond',
        provider => upstart,
    }
}
