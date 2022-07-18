class openstack::nova::fullstack::monitor {

    # Remove once puppet runs a couple times
    nrpe::monitor_service { 'nova-fullstack':
        ensure => absent,
    }

    # Make sure every flavor is assigned to an aggregate, to avoid
    # things like T259542
    nrpe::plugin { 'check_flavor_properties':
        source => 'puppet:///modules/openstack/monitor/nova/check_flavor_properties.py',
    }
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
