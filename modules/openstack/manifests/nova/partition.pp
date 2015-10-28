# creates a xfs partition for openstack nova
define openstack::nova::partition($partition_nr='1') {
    if (! $title =~ /^\/dev\/([hvs]d[a-z]+|md[0-9]+)$/) {
        fail("unable to init ${title} for nova")
    }

    $dev           = "${title}${partition_nr}"
    $dev_suffix    = regsubst($dev, '^\/dev\/(.*)$', '\1')
    $fs_label      = "virt-${dev_suffix}"
    $parted_cmd    = "parted --script --align optimal ${title}"
    $parted_script = "mklabel gpt mkpart ${fs_label} 4096s 100%"

    package { 'parted':
        ensure => 'present',
    }

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
}
