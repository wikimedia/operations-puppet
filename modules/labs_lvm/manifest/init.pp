# Class: labs_lvm
#
# Manages LVM in labs instance for extra storage.  labs_lvm
# only ensures the volume group exists, creating (and mounting)
# actual logical volumes is done with labs_lvm::volume.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class labs_lvm($device) {

    package { 'lvm2':
        ensure      => present,
    }

    file { '/usr/local/sbin/make-instance-vg':
        ensure      => file,
        source      => 'puppet:///modules/labs_lvm/make-instance-vg',
        requires    => Package['lvm2'],
        mode        => 0544,
        owner       => 'root',
        group       => 'root',
    }

    exec { 'create-volume-group':
        creates     => '/dev/vd',
        requires    => File['/usr/local/sbin/make-instance-vg'],
        command     => "/usr/local/sbin/make-instance-vg '$device'",
    }

}

class labs_lvm::volume(
    $name       = 'store',
    $mountpoint = '/mnt',
    $size       = '100%FREE',
    $fstype     = 'ext4',
    $mkfs_opt   = ''
) {

    file { '/usr/local/sbin/make-instance-vol':
        ensure      => file,
        source      => 'puppet:///modules/labs_lvm/make-instance-vol',
        requires    => Package['lvm2'],
        mode        => 0544,
        owner       => 'root',
        group       => 'root',
    }

    exec { "create-vd-$name":
        creates     => "/dev/vd/$name",
        requires    => [
                         File['/usr/local/sbin/make-instance-vol'],
                         Exec['create-volume-group']
                       ],
        command     => "/usr/local/sbin/make-instance-vol '$name' '$size' '$fstype' $mkfs_opt",
    }

    mount { $mountpoint:
        ensure      => mounted,
        atboot      => false,
        device      => "/dev/mapper/vd-$name",
        options     => "defaults,noauto",
        fstype      => $fstype,
        requires    => Exec["create-vd-$name"],
    }

}

