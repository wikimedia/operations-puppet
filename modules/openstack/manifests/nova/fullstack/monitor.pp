class openstack::nova::fullstack::monitor {

    nrpe::monitor_service { 'nova-fullstack':
        description   => 'nova instance creation test',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -C python3 -a nova-fullstack',
        contact_group => 'wmcs-team,admins',
        retries       => 2,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    # replaced by prometheus stats
    file { '/usr/local/bin/check_nova_fullstack_leaks.py':
        ensure => 'absent',
    }
    nrpe::monitor_service { 'check-fullstack-failures':
        ensure => 'absent',
    }

    # Script to make sure that every flavor is assigned to a host aggregate
    nrpe::plugin { 'check_flavor_properties':
        source => 'puppet:///modules/openstack/monitor/nova/check_flavor_properties.py',
    }

    # Make sure every flavor is assigned to an aggregate, to avoid
    #  things like T259542
    nrpe::monitor_service { 'check-flavor_aggregates':
        ensure         => 'present',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_flavor_properties',
        sudo_user      => 'root',
        description    => 'all nova flavors are assigned necessary properties',
        timeout        => 30,
        check_interval => 15,
        contact_group  => 'wmcs-team-email,wmcs-bots',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Host_aggregates';
    }
}
