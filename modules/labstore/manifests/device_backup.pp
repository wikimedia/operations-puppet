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

    systemd::timer::job { "block_sync-${local_lv}":
        ensure                    => present,
        description               => "Backup of remote ${remote_vg}/${remote_lv} to local ${local_vg}/${local_lv}",
        command                   => "${block_sync} ${remote_ip} ${remote_vg} ${remote_lv} ${remote_snapshot} ${local_vg} ${local_lv} ${local_snapshot} ${local_snapshot_size}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => $interval
            },
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
        logging_enabled           => false,
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }
}
