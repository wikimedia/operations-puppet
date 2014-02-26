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
    $volname    = $title,
    $mountat    = "/mnt/$title",
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

    exec { "create-vd-$volname":
        creates     => "/dev/vd/$volname",
        requires    => [
                         File['/usr/local/sbin/make-instance-vol'],
                         Exec['create-volume-group']
                       ],
        command     => "/usr/local/sbin/make-instance-vol '$volname' '$size' '$fstype' $mkfs_opt",
    }

    file { $mountat:
        ensure      => directory,
        owner       => 'root',
        group       => 'root',
        mode        => 0555,
    }

    mount { $mountat:
        ensure      => mounted,
        atboot      => false,
        device      => "/dev/mapper/vd-$volname",
        options     => "defaults,noauto",
        fstype      => $fstype,
        requires    => [
                         Exec["create-vd-$volname"],
                         File[$mountat],
                       ],
    }

}

