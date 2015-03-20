class openstack::nova::scheduler($novaconfig) {
    include openstack::repo

    package { "nova-scheduler":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-scheduler":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-scheduler"];
    }

    nrpe::monitor_service { 'check_nova_scheduler_process':
        description  => 'nova-scheduler process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-scheduler'",
    }
}

