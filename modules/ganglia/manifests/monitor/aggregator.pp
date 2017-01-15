# sets up a Ganglia Aggregator service
class ganglia::monitor::aggregator($sites) {
    require ::ganglia::monitor::packages
    include ::ganglia::configuration

    system::role { 'ganglia::monitor::aggregator': description => 'central Ganglia aggregator' }

    file { '/etc/ganglia/aggregators':
        ensure => directory,
        mode   => '0555',
    }

    # These files used to start multiple instances of the aggregator service.
    # Since using systemd they are not needed, now each instance is a separate
    # service created from a unit file template.
    # T124197 - see aggregator/instance.pp now
    if $::initsystem == 'upstart' {
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

    }

    site_instances{ $sites: }

    # with systemd each instance is a separate service spawned from a template
    # this is the old service that started multiple aggregators with upstart
    if $::initsystem == 'upstart' {
        service { 'ganglia-monitor-aggregator':
            ensure   => running,
            provider => upstart,
            name     => 'ganglia-monitor-aggregator',
        }
    }
}
