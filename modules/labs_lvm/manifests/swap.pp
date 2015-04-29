# = define: labs_lvm::swap
# Defines and activates a swap partition of a given size
#
# == Parameters
#
# [*size*]
#   Size of swap partition to allocate. Can be string of form 16GB or 80%FREE
define labs_lvm::swap(
    $size,
) {

    include labs_lvm

    $volume_path = "/dev/vd/${name}"

    exec { "create-swap-${name}":
        require   => [
            File['/usr/local/sbin/make-instance-vol'],
            Exec['create-volume-group']
        ],
        command   => "/usr/local/sbin/make-instance-vol ${name} ${size} swap",
        unless    => "/sbin/lvdisplay -c | grep ${volume_path}",
    }

    mount { "mount-swap-${name}":
        ensure  => present,
        name    => '-',
        atboot  => true,
        device  => $volume_path,
        options => 'defaults',
        fstype  => 'swap',
        require => Exec["create-swap-${name}"],
        notify  => Exec["swapon-${name}"]
    }

    exec { "swapon-${name}":
        refreshonly => true,
        command     => "/sbin/swapon ${volume_path}",
    }
}
