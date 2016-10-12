define labstore::device_backup (
    $remotehost,
    $remotedev,
    $localdev,
    $remotenice,
    $weekday,
    $hour=0,
) {

    include labstore::bdsync
    $remote_ip = ip_resolve($remotehost, 4)

    $day = {
        'sunday'    => 0,
        'monday'    => 1,
        'tuesday'   => 2,
        'wednesday' => 3,
        'thursday'  => 4,
        'friday'    => 5,
        'saturday'  => 6,
    }

    cron { "bdsync-${remotehost}-${remotedev}":
        ensure      => 'present',
        environment => 'MAILTO=labs-admins@wikimedia.org',
        user        => 'root',
        command     => "/usr/local/sbin/block_sync ${remote_ip} ${remotedev} ${localdev} ${remotenice}" 
        weekday     => $day[$weekday],
        hour        => $hour,
    }
}
