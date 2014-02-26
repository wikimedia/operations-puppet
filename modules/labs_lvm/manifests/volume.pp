# resource: labs_lvm::volume
#
# TODO: document
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

define labs_lvm::volume(
    $name       = $title,
    $mountpoint = "/mnt/$title",
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

    file { $mountpoint:
        ensure      => directory,
        owner       => 'root',
        group       => 'root',
        mode        => 0555,
    }

    mount { $mountpoint:
        ensure      => mounted,
        atboot      => false,
        device      => "/dev/mapper/vd-$name",
        options     => "defaults,noauto",
        fstype      => $fstype,
        requires    => [
                         Exec["create-vd-$name"],
                         File[$mountpoint],
                       ],
    }

}

