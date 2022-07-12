class openstack::monitor::neutron::l3_agent_conntrack (
) {
    file { '/usr/local/sbin/nrpe-neutron-conntrack':
        ensure => absent,
    }

    sudo::user { 'nagios_neutron_l3_agent_conntrack':
        ensure => absent,
    }

    nrpe::plugin { 'check_neutron_conntrack':
        source => 'puppet:///modules/openstack/monitor/neutron/nrpe-neutron-conntrack.py',
    }

    nrpe::monitor_service { 'check-neutron-conntrack':
        ensure        => 'present',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_neutron_conntrack',
        sudo_user     => 'root',
        description   => 'Check nf_conntrack usage in neutron netns',
        contact_group => 'wmcs-team-email,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
