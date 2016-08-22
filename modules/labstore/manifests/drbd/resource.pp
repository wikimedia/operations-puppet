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
# [*nodes]
#  Array with 2 values containing the node names where the resources are
#  meant to be available. Typically one of these nodes will be designated
#  primary, and the other secondary.
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
# Example:
# labstore::drbd_resource {'myresource':
#     nodes  => ['host1', 'host2'],
#     port   => 7788,
#     device => '/dev/drbd1',
#     disk   => '/dev/misc/blockdevice',
# }
#

define labstore::drbd::resource (
    $nodes,
    $port,
    $device,
    $disk,
) {

    require labstore::drbd::node

    if size(unique($nodes)) != 2 {
        fail('specify two nodes by hostname')
    }

    # cheap way to ensure uniqueness across resources
    labstore::drbd::resource::port { $port: }
    labstore::drbd::resource::port { $disk: }
    labstore::drbd::resource::port { $device: }

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

    if !defined(Host[$nodes[0]]) {
        host { $nodes[0]:
            ip => ipresolve($nodes[0]),
        }
    }

    if !defined(Host[$nodes[1]]) {
        host { $nodes[1]:
            ip => ipresolve($nodes[1]),
        }
    }
}

define labstore::drbd::resource::port {
}

define labstore::drbd::resource::device {
}

define labstore::drbd::resource::disk {
}
