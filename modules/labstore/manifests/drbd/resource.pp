# Manages a DRBD resource

# Resources need to be initialized first time.  This
# is not done automatically at the moment due to rarity
# and associated risk of programatic managment. This is a
# one time operation.
#
# 1. Apply resource files via Puppet - created in /etc/drbd.d/
# 2. Make sure the underlying disk is free
# 2a. May need to be zero'd out - 'dd if=/dev/zero of=/dev/vg/lv'
# 3. drbdadm create-md $resource
# 4. Create /dev/drbdx device
# 4a. drbdadm up $resource
# 5. Verify resource is secondary for both
# 5a. drbd-overview
# 5b. Connected Secondary/Secondary Inconsistent/Inconsistent
# 6. Promote a resource to primary
# 6a. drbdadm primary --force $resource
# 7. Format /dev/drbdx
#
# [*drbd_cluster]
#  Hash that has the `hostname` of each node with the associated
#  FQDN to use for replication (this is most likely a secondary interface).
#  {'nfs1' => 'eth1.nfs1.domain', 'nfs2' => eth1.nfs2.domain'}
#
#  ** the 'hostname' here should match literal `hostname` for the relevant node
#     in the cluster for DRBD to function correctly.  This is not used
#     for resolution.  Using the FQDN or another representation causes
#     DRBD to ignore the resource.
#
# [*port]
#  Integer port number for DRBD TCP connections. Needs to be unique for
#  every resource, by convention DRBD uses TCP ports from 7788 upwards.
#
# [*device]
#  Path for the DRBD device
#
# [*disk]
#  Path for underlying volume on disk
#
# [*mount_path]
#  Path allocated to mount block device
#
# Example:
# labstore::drbd_resource {'myresource':
#     drbd_cluster => {'nfs1' => 'eth1.nfs1.domain', 'nfs2' => eth1.nfs2.domain'},
#     port         => 7788,
#     device       => '/dev/drbd1',
#     disk         => '/dev/misc/blockdevice',
# }
#

define labstore::drbd::resource (
    $drbd_cluster,
    $port,
    $device,
    $disk,
    $mount_path,
) {

    require ::labstore::drbd::node

    $drbd_hosts = keys($drbd_cluster)

    if size(unique($drbd_hosts)) != 2 {
        fail('specify two nodes by hostname as keys')
    }

    # cheap way to ensure uniqueness across resources
    labstore::drbd::resource::port { $port: }
    labstore::drbd::resource::port { $disk: }
    labstore::drbd::resource::port { $device: }
    labstore::drbd::resource::port { $mount_path: }

    file { "/etc/drbd.d/${name}.res":
        content => template('labstore/drbd/drbd_resource.res.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/etc/drbd.d/global_common.conf'],
        notify  => Exec["${name}-drbdadm-adjust"],
    }

    exec { "${name}-drbdadm-adjust":
        command     => "/sbin/drbdadm adjust ${name}",
        onlyif      => "/sbin/drbdadm role ${name} | grep -i -e ^primary -e ^secondary",
        logoutput   => true,
        refreshonly => true,
    }
}

# lint:ignore:autoloader_layout
define labstore::drbd::resource::port {
}

define labstore::drbd::resource::device {
}

define labstore::drbd::resource::disk {
}
# lint:endignore
