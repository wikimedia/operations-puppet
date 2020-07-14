class openstack::monitor::neutron::l3_agent_conntrack (
) {
    $script = '/usr/local/sbin/nrpe-neutron-conntrack'
    file { $script:
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/neutron/nrpe-neutron-conntrack.py',
    }

    nrpe::monitor_service { 'check-neutron-conntrack':
        ensure        => 'present',
        nrpe_command  => $script,
        description   => 'Check nf_conntrack usage in neutron netns',
        require       => File[$script],
        contact_group => 'wmcs-team,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
