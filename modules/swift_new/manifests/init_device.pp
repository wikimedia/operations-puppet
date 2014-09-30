define swift_new::init_device($partition_nr='1') {
    require base::platform

    if (! $title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) {
        fail("unable to init ${title} for swift")
    }

    $dev           = "${title}${partition_nr}"
    $dev_suffix    = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $fs_label      = "swift-${dev_suffix}"
    $parted_cmd    = "parted --script --align optimal ${title}"
    $parted_script = "mklabel gpt mkpart ${fs_label} 0 100%"
    $mkfs_cmd      = "mkfs -t xfs -i size=512 ${dev}"

    exec { "parted-${title}":
        path    => '/usr/bin:/bin:/usr/sbin:/sbin',
        require => Package['parted'],
        command => "${parted_cmd} ${parted_script}",
        creates => $dev,
    }

    exec { "mkfs-${title}":
        command => $mkfs_cmd,
        path    => '/sbin/:/usr/sbin/',
        require => Package['xfsprogs'],
        before  => Exec["parted-${title}"],
        unless  => "xfs_admin -l ${dev}",
    }

    swift_new::label_filesystem { $dev:
        before => Exec["mkfs-${title}"],
    }

    swift_new::mount_filesystem { $dev: }
}
