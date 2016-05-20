# Class: role::labs::nfs::fileserver
#
# The role class for the NFS servers that provide general filesystem
# services to Labs.
#
class role::labs::nfs::fileserver($monitor = 'eth0') {
    include labstore::fileserver

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    class { '::labstore::monitoring':
        monitor_iface => $monitor,
    }
}
