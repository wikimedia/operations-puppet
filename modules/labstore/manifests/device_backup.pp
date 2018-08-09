define labstore::device_backup (
    $remotehost,
    $remote_vg,
    $remote_lv,
    $remote_snapshot,
    $local_vg,
    $local_lv,
    $local_snapshot,
    $local_snapshot_size,
    $weekday,
    $hour=0,
    $minute=0,
) {

    include ::labstore::bdsync
    $remote_ip = ipresolve($remotehost, 4)

    $day = {
        'sunday'    => 'Sun',
        'monday'    => 'Mon',
        'tuesday'   => 'Tue',
        'wednesday' => 'Wed',
        'thursday'  => 'Thu',
        'friday'    => 'Fri',
        'saturday'  => 'Sat',
    }

    $block_sync='/usr/local/sbin/block_sync'

    systemd::unit { 'block_sync':
        ensure  => 'present',
        content => template('labstore/device_backup/device_backup.systemd.erb'),
    }

    systemd::timer { 'block_sync':
        timer_intervals => [{
            'start'    => 'OnCalendar',
            'interval' => sprintf('%s *-*-* %02d:%02d:00', $day[$weekday], $hour, $minute)
            }],
        unit_name       => 'block_sync.service',
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }
}
