define labs_lvm::swap(
    $size,
) {

    include labs_lvm

    # Both these are symlinks to /dev/dm*, but swapon returns mapper and lvdisplay volume
    $volume_path = "/dev/vd/${name}"
    $mapper_path = "/dev/mapper/vd-${name}"

    exec { "create-swap-${name}":
        require   => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command   => "/usr/local/sbin/make-instance-vol ${name} ${size} swap",
        unless    => "/sbin/lvdisplay -c | grep ${volume_path}",
    }

    exec { "swapon-$name":
        unless  => "/sbin/swapon -s | grep ${mapper_path}",
        command => "/sbin/swapon ${mapper_path}",
        require => Exec["create-swap-${name}"],
    }
}
