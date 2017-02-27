class ganglia::monitor::service() {
    Class[ganglia::monitor::config] -> Class[ganglia::monitor::service]

    if os_version('debian >= jessie') {
        file { '/etc/systemd/system/ganglia-monitor-aggregator@.service':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => "puppet:///modules/${module_name}/systemd/ganglia-monitor-aggregator@.service",
            before => Service['ganglia-monitor'],
        }

        file { '/etc/systemd/system/ganglia-monitor.service':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => "puppet:///modules/${module_name}/systemd/ganglia-monitor.service",
            before => Service['ganglia-monitor'],
        }
    }

    service { 'ganglia-monitor':
        ensure   => running,
        provider => $::initsystem,
    }
}
