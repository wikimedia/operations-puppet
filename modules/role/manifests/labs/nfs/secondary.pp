class role::labs::nfs::primary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::secondary':
        description => 'NFS primary share cluster',
    }

    include labstore::fileserver::primary
    include labstore::backup_keys

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }
}
