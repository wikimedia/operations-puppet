class base::initramfs($localtop_sleep = '5s') {
    file { '/etc/initramfs-tools/scripts/local-top/mdadm-sleep':
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        content => template('base/initramfs_sleep.erb'),
        notify  => Exec['update-initramfs'],
    }

    exec { 'update-initramfs':
        refreshonly => true,
        command     => 'update-initramfs -u -k all',
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
}
