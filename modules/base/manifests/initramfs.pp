class base::initramfs($localtop_sleep = '5s') {
    initramfs::script { 'mdadm-sleep':
        boot_stage => 'local-top',
        content    => template('base/initramfs_sleep.erb'),
    }
}
