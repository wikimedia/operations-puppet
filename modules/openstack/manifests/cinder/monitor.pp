class openstack::cinder::monitor() {
    require openstack::cinder::service

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
