define swift::init_device($partition_nr='1') {
    if (! $title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) {
        fail("unable to init ${title} for swift")
    }

    $dev           = "${title}${partition_nr}"
    $dev_suffix    = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $fs_label      = "swift-${dev_suffix}"
    $parted_cmd    = "parted --script --align optimal ${title}"
    $parted_script = "mklabel gpt mkpart ${fs_label} 1M 100%"

    exec { "parted-${title}":
        path    => '/usr/bin:/bin:/usr/sbin:/sbin',
        require => Package['parted'],
        command => "${parted_cmd} ${parted_script}",
        creates => $dev,
    }

    exec { "mkfs-${dev}":
        command => "mkfs -t xfs -L ${fs_label} -i size=512 ${dev}",
        path    => '/sbin/:/usr/sbin/',
        require => [Package['xfsprogs'], Exec["parted-${title}"]],
        unless  => "xfs_admin -l ${dev}",
    }

    swift::mount_filesystem { $dev:
        require => Exec["mkfs-${dev}"],
    }
}
