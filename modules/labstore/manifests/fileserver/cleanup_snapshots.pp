# = Define: labstore::fileserver::cleanup_snapshots
# Simple systemd based unit to clean up snapshot
# volumes created by replication
#
# Parameters:
#   keep_free    = free space to keep (in terabytes)
#   volume_group = volume group to clean
#
define labstore::fileserver::cleanup_snapshots(
    $keep_free,
    $volume_group = $title,
) {
    base::service_unit { "cleanup-snapshots-${volume_group}":
        ensure          => present,
        template_name   => 'cleanup-snapshots',
        systemd         => true,
        declare_service => false,
    }

    file { "/etc/systemd/system/cleanup-snapshots-${volume_group}.timer":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labstore/initscripts/cleanup.timer.erb'),
    }

    nrpe::monitor_systemd_unit_state { "cleanup-snapshots-${volume_group}":
        description    => "Last cleanup of snapshots in the ${volume_group} vg",
        expected_state => 'periodic 90000', # 25h (i.e. daily but with a bit of give)
    }
}
