define labs_lvm::swap(
    $size,
) {

    include labs_lvm
    $name = "swap-${title}"
    $volume_path = '/dev/vd/$name'

    exec { "create-swap-${title}":
        require   => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command   => "/usr/local/sbin/make-instance-vol $name '${size}' swap",
        unless    => "/sbin/lvdisplay -c | grep $volume_path"
    }

    exec { 'swapon-$title':
        unless  => "/sbin/swapon -s | grep $volume_path",
        command => "/sbin/swapon $name",
    }
}
