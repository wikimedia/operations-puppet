# resource: labs_lvm::volume
#
# labs_lvm::volume allocates a LVM volume from the volume group
# created by the labs_lvm class.
#
# Parameters:
#   volname  => arbitrary identifier used to construct the volume
#               name, and the default mountpoint.  Needs to be
#               unique in the instance.  Defaults to the resource
#               title.
#   mountat  => point where the volume is to be mounted
#   size     => size of the volume, using the lvcreate(8) syntax.
#               defaults to allocate all of the available space
#               in the volume group.  Note that if you use the
#               default value, any /other/ volumes must be created
#               before that one and should be marked as dependencies.
#   fstype   => filesystem type.  Defaults to ext4.
#   mkfs_opt => options for the mkfs if the filesystem needs to
#               be created.
#
# Requires:
#   The node must have included the labs_lvm class.
#
# Sample Usage:
#   labs_lvm::volume { 'storage': mountat => '/mnt' }
#

define labs_lvm::volume(
    $volname    = $title,
    $mountat    = "/mnt/$volume",
    $size       = '100%FREE',
    $fstype     = 'ext4',
    $mkfs_opt   = ''
) {

    file { '/usr/local/sbin/make-instance-vol':
        ensure      => file,
        source      => 'puppet:///modules/labs_lvm/make-instance-vol',
        require     => Package['lvm2'],
        mode        => 0544,
        owner       => 'root',
        group       => 'root',
    }

    exec { "create-vd-$volname":
        creates     => "/dev/vd/$volname",
        require     => [
                         File['/usr/local/sbin/make-instance-vol'],
                         Exec['create-volume-group']
                       ],
        command     => "/usr/local/sbin/make-instance-vol '$volname' '$size' '$fstype' $mkfs_opt",
    }

    file { $mountat:
        ensure      => directory,
    }

    mount { $mountat:
        ensure      => mounted,
        atboot      => false,
        device      => "/dev/mapper/vd-$volname",
        options     => "defaults,noauto",
        fstype      => $fstype,
        require     => [
                         Exec["create-vd-$volname"],
                         File[$mountat],
                       ],
    }

}

