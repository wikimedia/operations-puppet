class openstack::cinder::monitor(
    $active,
    $critical=false,
    $contact_groups='wmcs-bots,admins',
) {

    require openstack::cinder::service

    # nagios doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { 'cinder-api':
        ensure        => $ensure,
        description   => 'cinder-api http',
        check_command => 'check_http_on_port!18776',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_cinder_scheduler_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'cinder-scheduler process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python.* /usr/bin/cinder-scheduler'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_cinder_volume_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'cinder-volume process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python.* /usr/bin/cinder-volume'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    # The backup process uses snapshots owned by the 'admin' project.
    #
    # There should really never be more than one snapshot at a time
    #  since we clean them up after running the backup job. Alert
    #  if snapshots start to pile up.
    file { '/usr/local/bin/check_cinder_snapshot_leaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/cinder/check_cinder_snapshot_leaks.py',
    }

    nrpe::monitor_service { 'check-cinder-snapshot-leaks':
        ensure        => 'present',
        nrpe_command  => '/usr/local/bin/check_cinder_snapshot_leaks.py',
        description   => 'Check for snapshots leaked by cinder backup agent',
        require       => File['/usr/local/bin/check_cinder_snapshot_leaks.py'],
        contact_group => 'wmcs-team-email,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Check_for_snapshots_leaked_by_cinder_backup_agent',
    }
}
