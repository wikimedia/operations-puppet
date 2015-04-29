define labs_lvm::swap(
    $size,
) {

    include labs_lvm

    $volume_path = "/dev/vd/$name"

    exec { "create-swap-${name}":
        require   => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command   => "/usr/local/sbin/make-instance-vol $name '${size}' swap",
        unless    => "/sbin/lvdisplay -c | grep $volume_path"
    }

    exec { "swapon-$name":
        unless  => "/sbin/swapon -s | grep $volume_path",
        command => "/sbin/swapon $volume_path",
    }
}
