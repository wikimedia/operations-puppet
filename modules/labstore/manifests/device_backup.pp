define labstore::device_backup (
    $remotehost,
    $remote_vg,
    $remote_lv,
    $remote_snapshot,
    $localdev,
    $weekday,
    $hour=0,
    $minute=0,
) {

    include labstore::bdsync
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
    cron { "block_sync-${remote_vg}/${remote_lv}=>${localdev}":
        ensure      => 'present',
        user        => 'root',
        command     => "${block_sync} ${remote_ip} ${remote_vg} ${remote_lv} ${remote_snapshot} ${localdev}",
        weekday     => $day[$weekday],
        hour        => $hour,
        minute      => $minute,
        environment => 'MAILTO=labs-admin@lists.wikimedia.org',
    }
}
