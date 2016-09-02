# defines an rsync server on an instance
define openstack::nova::instancersync (
    $hostname = undef) {

    rsync::server::module { "nova_instance_rsync_${hostname}":
        path        => '/var/lib/nova/instances',
        read_only   => 'no',
        hosts_allow => ["${hostname}.${::site}.wmnet"],
    }
}
