class ganglia::monitor::aggregator($sites) {
    require ganglia::monitor::packages
    include ganglia::configuration

    system::role { 'ganglia::monitor::aggregator': description => 'central Ganglia aggregator' }

    file { '/etc/ganglia/aggregators':
        ensure => directory,
        mode   => '0555',
    }

    file { '/etc/init/ganglia-monitor-aggregator.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/upstart/ganglia-monitor-aggregator.conf",
        before => Service['ganglia-monitor-aggregator'],
    }

    file { '/etc/init/ganglia-monitor-aggregator-instance.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/upstart/ganglia-monitor-aggregator-instance.conf",
        before => Service['ganglia-monitor-aggregator'],
    }

    define site_instances() {
        # Instantiate aggregators for all clusters for this site ($title)
        $cluster_list = suffix(keys($ganglia::configuration::clusters), "_${title}")
        instance { $cluster_list:
            monitored_site => $title
        }
    }

    site_instances{ $sites: }

    if os_version('debian >= jessie') {
       $ganglia_provider = 'systemd'
    } else {
       $ganglia_provider = 'upstart'
    }

    service { 'ganglia-monitor-aggregator':
        ensure   => running,
        provider => $ganglia_provider,
        name     => 'ganglia-monitor-aggregator',
    }
}
