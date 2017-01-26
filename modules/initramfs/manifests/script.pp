define initramfs::script($boot_stage='', $content='') {
    include ::initramfs

    case $boot_stage {
        'init-bottom', 'init-premount', 'init-top', 'local-bottom', 'local-premount', 'local-top', 'nfs-bottom', 'nfs-premount', 'nfs-top', 'panic': {}
        default: { fail("Unsupported initramfs stage: ${boot_stage}") }
    }

    file { "/etc/initramfs-tools/scripts/${boot_stage}/${title}":
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => $content,
        notify  => Exec['update-initramfs'],
    }
}
