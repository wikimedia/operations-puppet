class interface::rps::modparams {
    include initramfs

    file { '/etc/modprobe.d/rps.conf':
        content => template("${module_name}/rps.conf.erb"),
        notify  => Exec['update-initramfs']
    }
}
