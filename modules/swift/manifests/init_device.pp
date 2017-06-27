define swift::init_device($partition_nr='1') {
    if ($title !~ /^([hvs]d[a-z]+|md[0-9]+)$/) {
        fail("Invalid name ${title} for swift::init_device")
    }

    $dev           = "/dev/swift/${title}${partition_nr}"
    $dev_nopart    = "/dev/swift/${title}"
    $dev_suffix    = "${title}${partition_nr}"
    $fs_label      = "swift-${dev_suffix}"
    $parted_cmd    = "parted --script --align optimal ${dev_nopart}"
    $parted_script = "mklabel gpt mkpart ${fs_label} 1M 100%"

    exec { "parted-${dev}":
        path    => '/usr/bin:/bin:/usr/sbin:/sbin',
        require => Package['parted'],
        command => "${parted_cmd} ${parted_script}",
        creates => $dev,
    }

    exec { "mkfs-${dev}":
        command => "mkfs -t xfs -L ${fs_label} -i size=512 ${dev}",
        path    => '/sbin/:/usr/sbin/',
        require => [Package['xfsprogs'], Exec["parted-${dev}"]],
        unless  => "xfs_admin -l ${dev}",
    }

    swift::mount_filesystem { $dev_suffix:
        require => Exec["mkfs-${dev}"],
    }
}
