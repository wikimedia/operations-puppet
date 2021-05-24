class udev {
    if debian::codename::le('buster') {
        $udevadm = '/sbin/udevadm'
    } else {
        $udevadm = '/usr/bin/udevadm'
    }

    exec { 'udev_reload':
        command     => "${udevadm} control --reload && ${udevadm} trigger",
        refreshonly => true,
    }
}
