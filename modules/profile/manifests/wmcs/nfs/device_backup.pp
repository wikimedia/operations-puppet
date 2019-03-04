define profile::wmcs::nfs::device_backup (
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
    include profile::wmcs::nfs::bdsync

    $remote_ip = ipresolve($remotehost, 4)
    $block_sync = '/usr/local/sbin/block_sync'

    systemd::unit { "block_sync-${local_lv}.service":
        ensure  => 'present',
        content => systemd_template('wmcs/nfs/block_sync'),
    }

    systemd::timer { "block_sync-${local_lv}":
        timer_intervals => [{
            'start'    => 'OnCalendar',
            'interval' => $interval
            }],
        unit_name       => "block_sync-${local_lv}.service",
    }

}
