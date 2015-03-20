class openstack::nova::conductor($novaconfig) {
    include openstack::repo

    package { "nova-conductor":
        ensure  => present,
        require => Class["openstack::repo"];
    }

    service { "nova-conductor":
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package["nova-conductor"];
    }

    nrpe::monitor_service { 'check_nova_conductor_process':
        description  => 'nova-conductor process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-conductor'",
    }
}
