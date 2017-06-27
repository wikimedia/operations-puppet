define swift::label_filesystem {
    if ($title !~ /^[hvs]d[a-z]+[0-9]+$/) {
        fail("Invalid name ${title} for swift::label_filesystem")
    }

    $dev        = "/dev/swift/${title}"
    $fs_label   = "swift-${title}"

    exec { "xfs_label-${dev}":
        command => "xfs_admin -L ${fs_label} ${dev}",
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        require => Package['xfsprogs'],
        unless  => "xfs_admin -l ${dev} | grep -q ${fs_label}"
    }
}
