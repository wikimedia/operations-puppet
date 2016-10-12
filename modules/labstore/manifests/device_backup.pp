define labstore::device_backup (
    $remotehost,
    $remote_vg,
    $remote_lv,
    $localdev,
    $weekday,
    $hour=0,
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

    # Establish what list these alerts should go to
    # environment => 'MAILTO=labs-admins@wikimedia.org'
    $block_sync='/usr/local/sbin/block_sync'
    cron { "${block_sync}-${remotehost}-${remotedev}":
        ensure  => 'present',
        user    => 'root',
        command => "${block_sync} ${remote_ip} ${remote_vg} ${remote_lv} ${localdev}",
        weekday => $day[$weekday],
        hour    => $hour,
    }
}
