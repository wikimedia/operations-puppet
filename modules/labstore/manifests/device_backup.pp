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
        'sunday'    => 0,
        'monday'    => 1,
        'tuesday'   => 2,
        'wednesday' => 3,
        'thursday'  => 4,
        'friday'    => 5,
        'saturday'  => 6,
    }

    $block_sync='/usr/local/sbin/block_sync'
    cron { "block_sync-${remote_vg}/${remote_lv}=>${local_vg}/${local_lv}":
        ensure      => 'present',
        user        => 'root',
        command     => "${block_sync} ${remote_ip} ${remote_vg} ${remote_lv} ${remote_snapshot} ${local_vg} ${local_lv} ${local_snapshot} ${local_snapshot_size}",
        weekday     => $day[$weekday],
        hour        => $hour,
        minute      => $minute,
        environment => 'MAILTO=labs-admin@lists.wikimedia.org',
        require     => File['/usr/local/sbin/snapshot-manager'],
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }
}
