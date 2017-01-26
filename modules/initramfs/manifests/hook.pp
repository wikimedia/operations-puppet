define initramfs::hook($content='') {
    include ::initramfs

    file { "/etc/initramfs-tools/hooks/${title}":
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => $content,
        notify  => Exec['update-initramfs'],
    }
}
