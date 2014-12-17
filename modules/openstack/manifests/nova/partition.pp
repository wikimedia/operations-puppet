define openstack::nova::partition($partition_nr='1') {
    if (! $title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) {
        fail("unable to init ${title} for nova")
    }

    $dev           = "${title}${partition_nr}"
    $dev_suffix    = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $fs_label      = "virt-${dev_suffix}"
    $parted_cmd    = "parted --script --align optimal ${title}"
    $parted_script = "mklabel gpt mkpart ${fs_label} 4096s 100%"

    package { [
        'parted',
        'xfsprogs',
        ]:
        ensure => 'present',
    }


    exec { "parted-${title}":
        path    => '/usr/bin:/bin:/usr/sbin:/sbin',
        require => Package['parted'],
        command => "${parted_cmd} ${parted_script}",
        creates => $dev,
    }

    exec { "mkfs-${dev}":
        command => "mkfs -t xfs -L $fs_label -i size=512 ${dev}",
        path    => '/sbin/:/usr/sbin/',
        require => [Package['xfsprogs'], Exec["parted-${title}"]],
        unless  => "xfs_admin -l ${dev}",
    }

    openstack::nova::mount_filesystem { $dev:
        require => Exec["mkfs-${dev}"],
    }
}


define openstack::nova::mount_filesystem {
    $dev         = $title
    $dev_suffix  = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $mount_point = '/srv'

    file { "mountpoint-${mount_point}":
        ensure => 'directory',
        path   => $mount_point,
        owner  => 'nova',
        group  => 'nova',
        mode   => '0750',
    }

    mount { $mount_point:
        ensure   => 'present',
        device   => "LABEL=virt-${dev_suffix}",
        name     => $mount_point,
        fstype   => 'xfs',
    }
}
