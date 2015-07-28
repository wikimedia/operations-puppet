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
    base::service_unit { "cleanup-snapshot-${volume_group}":
        template_name   => 'cleanup-snapshot',
        ensure          => present,
        systemd         => true,
        declare_service => false,
    }
}
