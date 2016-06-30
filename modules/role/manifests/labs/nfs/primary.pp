#
# The role class for the NFS servers that provide general filesystem
# services to Labs.
#

class role::labs::nfs::primary($monitor = 'eth0') {

    system::role { 'role::labs::nfs::primary':
        description => 'NFS primary share cluster',
    }

    include labstore::fileserver::primary
    include labstore::backup_keys
    include labstore::monitoring::interfaces
    include labstore::monitoring::ldap
    include labstore::monitoring::nfsd

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }

    # Use the CFQ I/O scheduler
    grub::bootparam { 'elevator':
        value => 'cfq',
    }

}
