class openstack2::nova::network::monitor(
    $active,
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/lib/nagios/plugins/check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
        mode   => '0755',
    }

    nrpe::monitor_service { 'check_nova_network_process':
        ensure       => $ensure,
        description  => 'nova-network process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-network'",
        critical     => true,
    }

    nrpe::monitor_service { 'conntrack_table_size':
        ensure       => $ensure,
        description  => 'Check size of conntrack table',
        nrpe_command => '/usr/lib/nagios/plugins/check_conntrack 80 90',
        require      => File['/usr/lib/nagios/plugins/check_conntrack'],
        contact_group => 'admins',
    }
}
