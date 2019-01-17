define labstore::device_backup (
    String $remotehost,
    String $remote_vg,
    String $remote_lv,
    String $remote_snapshot,
    String $local_vg,
    String $local_lv,
    String $local_snapshot,
    String $local_snapshot_size,
    String $interval,  # https://www.freedesktop.org/software/systemd/man/systemd.time.html
) {
    include ::labstore::bdsync
    $remote_ip = ipresolve($remotehost, 4)

    $block_sync='/usr/local/sbin/block_sync'

    systemd::unit { 'block_sync.service':
        ensure  => 'present',
        content => template('labstore/device_backup/device_backup.systemd.erb'),
    }

    systemd::timer { 'block_sync':
        timer_intervals => [{
            'start'    => 'OnCalendar',
            'interval' => $interval
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
