class interface::rps::modparams {
    file { '/etc/modprobe.d/rps.conf':
        content => template("${module_name}/rps.conf.erb"),
        notify  => Exec['update-initramfs-rps']
    }

    exec { 'update-initramfs-rps':
        command     => '/usr/sbin/update-initramfs -u',
        refreshonly => true
    }
}
