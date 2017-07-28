# openstack scheduler determines on which host a
# particular instance should run
class openstack::nova::scheduler(
    $openstack_version=$::openstack::version,
){

    package { 'nova-scheduler':
        ensure  => present,
    }

    file { '/usr/lib/python2.7/dist-packages/nova/scheduler/filters/scheduler_pool_filter.py':
        source  => "puppet:///modules/openstack/${openstack_version}/nova/scheduler_pool_filter.py",
        notify  => Service['nova-scheduler'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['nova-scheduler'],
    }

    # The scheduler won't ever check the policy file, but nova-common
    #  seems to expect it to be here, so install to make apt happy.
    file { '/etc/nova/policy.json':
        source => "puppet:///modules/openstack/${openstack_version}/nova/policy.json",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    if $::fqdn == hiera('labs_nova_controller') {
        service { 'nova-scheduler':
            ensure    => running,
            subscribe => File['/etc/nova/nova.conf'],
            require   => Package['nova-scheduler'];
        }

        nrpe::monitor_service { 'check_nova_scheduler_process':
            description  => 'nova-scheduler process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-scheduler'",
        }
    } else {
        service { 'nova-scheduler':
            ensure  => stopped,
            require => Package['nova-scheduler'];
        }
    }
}
