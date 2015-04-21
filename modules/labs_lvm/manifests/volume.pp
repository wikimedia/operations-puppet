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
#   options  => mount options
#
# Requires:
#   The node must have included the labs_lvm class.
#
# Sample Usage:
#   labs_lvm::volume { 'storage': mountat => '/mnt' }
#

define labs_lvm::volume(
    $volname    = $title,
    $mountat    = "/mnt/${volname}",
    $mountowner = 'root',
    $mountgroup = 'root',
    $mountmode  = '755',
    $size       = '100%FREE',
    $fstype     = 'ext4',
    $mkfs_opt   = '',
    $options    = 'defaults',
) {
    include labs_lvm

    exec { "create-vd-${volname}":
        creates     => "/dev/vd/${volname}",
        unless      => "/bin/mountpoint -q '${mountat}'",
        logoutput   => 'on_failure',
        require     => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command     => "/usr/local/sbin/make-instance-vol '${volname}' '${size}' '${fstype}' ${mkfs_opt}",
    }

    file { $mountat:
        ensure      => directory,
        owner       => $mountowner,
        group       => $mountgroup,
        mode        => $mountmode,
    }

    mount { $mountat:
        ensure      => mounted,
        atboot      => true,
        device      => "/dev/vd/${volname}",
        options     => $options,
        fstype      => $fstype,
        require     => [
            Exec["create-vd-${volname}"],
            File[$mountat],
        ],
    }

    labs_lvm::extend { $mountat:
        size       => $size,
        require    => [ Mount[$mountat] ],
    }

}

