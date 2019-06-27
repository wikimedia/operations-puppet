class openstack::nova::fullstack::monitor {

    nrpe::monitor_service { 'nova-fullstack':
        description   => 'nova instance creation test',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a nova-fullstack',
        contact_group => 'wmcs-team,admins',
        retries       => 2,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    # Count VMs in admin-monitoring and alert if there are too
    #  many -- each leaked VM is a fullstack failure.
    file { '/usr/local/bin/check_nova_fullstack_leaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/fullstack/check_nova_fullstack_leaks.py',
    }

    nrpe::monitor_service { 'check-fullstack-failures':
        ensure        => 'present',
        nrpe_command  => '/usr/local/bin/check_fullstack_leaks.py',
        description   => 'Check for VMs leaked by the nova-fullstack test',
        require       => File['/usr/local/bin/check_nova_fullstack_leaks.py'],
        contact_group => 'wmcs-team,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting#Nova-fullstack',
    }
}
