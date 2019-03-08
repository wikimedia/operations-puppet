class openstack::nova::network::monitor(
    $critical=false,
    $contact_groups='wmcs-bots,admins',
    ) {

    file { '/usr/lib/nagios/plugins/check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
        mode   => '0755',
    }

    nrpe::monitor_service { 'check_nova_network_process':
        ensure        => 'present',
        critical      => $critical,
        description   => 'nova-network process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-network'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'conntrack_table_size':
        ensure        => 'present',
        critical      => $critical,
        description   => 'Check size of conntrack table',
        nrpe_command  => '/usr/lib/nagios/plugins/check_conntrack 80 90',
        require       => File['/usr/lib/nagios/plugins/check_conntrack'],
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
