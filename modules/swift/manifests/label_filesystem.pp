define swift::label_filesystem {
    $dev        = $title
    $dev_suffix = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $fs_label   = "swift-${dev_suffix}"

    exec { "xfs_label-${dev}":
        command => "xfs_admin -L ${fs_label} ${dev}",
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        require => Package['xfsprogs'],
        unless  => "xfs_admin -l ${dev} | grep -q ${fs_label}",
    }
}
