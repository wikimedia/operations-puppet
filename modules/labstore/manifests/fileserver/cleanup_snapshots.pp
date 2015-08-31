# = Define: labstore::fileserver::cleanup_snapshots
# Simple systemd based unit to clean up snapshot
# volumes created by replication
#
# Parameters:
#   volume_group = volume group to clean
#   keep_free    = free space to keep (in terabytes)
#
define labstore::fileserver::cleanup_snapshots(
    $volume_group = $title,
    $keep_free,
) {
    base::service_unit { "cleanup-snapshots-${volume_group}":
        template_name   => 'cleanup-snapshots',
        ensure          => present,
        systemd         => true,
        declare_service => false,
    }

    file { "/etc/systemd/system/cleanup-${volume_group}.timer":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labstore/initscripts/cleanup.timer.erb'),
    }

    nrpe::monitor_systemd_unit_state { "cleanup-${volume_group}":
        description    => "Last cleanup of snapshots in the ${volume_group} vg",
        expected_state => 'periodic 90000', # 25h (i.e. daily but with a bit of give)
    }
}
