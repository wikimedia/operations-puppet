class ganglia::monitor::service() {
    Class[ganglia::monitor::config] -> Class[ganglia::monitor::service]

    if $::operatingsystem == 'Ubuntu' and os_version('ubuntu < trusty') {
        file { '/etc/init/ganglia-monitor.conf':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => "puppet:///modules/${module_name}/upstart/ganglia-monitor.conf",
            before => Service['ganglia-monitor'],
        }
    }

    service { 'ganglia-monitor':
        ensure   => running,
        provider => $::initsystem,
    }
}
