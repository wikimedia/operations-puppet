class base::initramfs($sleep = '5s') {
    initramfs::script { 'mdadm-sleep':
        boot_stage => 'init-premount',
        content    => template('base/initramfs_sleep.erb'),
    }
}
