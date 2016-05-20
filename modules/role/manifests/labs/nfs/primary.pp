#
# The role class for the NFS servers that provide general filesystem
# services to Labs.
#

class role::labs::nfs::primary($monitor = 'eth0') {

    include labstore::fileserver::primary
    include labstore::monitoring::interfaces
    include labstore::monitoring::ldap

    # Enable RPS to balance IRQs over CPUs
    interface::rps { $monitor: }
}
