# resource: labs_lvm::swap
#
# labs_lvm::swap allocates a LVM volume from the volume group
# created by the labs_lvm class as swap for the instance.
#
# Parameters:
#   volname  => arbitrary identifier used to construct the volume
#               name.  Needs to be unique in the instance.  Defaults
#               to the resource title.
#   size     => size of the volume, using the lvcreate(8) syntax.
#               defaults to allocate all of the available space
#               in the volume group.  Note that if you use the
#               default value, any /other/ volumes must be created
#               before that one and should be marked as dependencies.
#   options  => mount options
#
# Requires:
#   The node must have included the labs_lvm class.
#
# Sample Usage:
#   labs_lvm::swap { 'moar_swap': size => '10G' }
#

define labs_lvm::volume(
    $volname    = $title,
    $size       = '100%FREE',
    $options    = 'defaults',
) {
    include labs_lvm

    exec { "create-vd-${volname}":
        creates     => "/dev/vd/${volname}",
        logoutput   => 'on_failure',
        require     => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command     => "/usr/local/sbin/make-instance-vol '${volname}' '${size}' swap",
    }

    mount { "swap-${volname}":
        name    => '-',
        atboot  => true,
        ensure  => present,
        device  => "/dev/vd/${volname}",
        options => $options,
        fstype  => "swap",
        require => Exec["create-vd-${volname}"],
        notify  => Exec["swapon-${volname}"],
    }

    exec { "swapon-${volname}":
        refreshonly => true,
        command     => "/sbin/swapon /dev/vd/${volname}",
        require     => Mount["swap-${volname}"],
    }

}

