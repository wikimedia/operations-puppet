define package_builder::pbuilder_base(
    $distribution='jessie',
    $components='main',
    $mirror='http://nova.clouds.archive.ubuntu.com/ubuntu/',
    $basepath='/var/cache/pbuilder',
    $hook_components=undef,
    $keyring=undef,
) {
    if $keyring {
        $arg = "--debootstrapopts --keyring=${keyring}"
    } else {
        $arg = ''
    }

    $command = "/usr/sbin/cowbuilder --create \
                        --mirror ${mirror} \
                        --distribution ${distribution} \
                        --components \"${components}\" \
                        --basepath \"${basepath}/base-${distribution}.cow\" \
                        --debootstrapopts --variant=buildd \
                        ${arg}"

    exec { "cowbuilder_init_${distribution}":
        command => $command,
        creates => "${basepath}/base-${distribution}.cow",
    }

    file { "/var/cache/pbuilder/hooks/${distribution}":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { "/var/cache/pbuilder/hooks/${distribution}/D01apt.wikimedia.org":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('package_builder/D01apt.wikimedia.org.erb'),
    }
}
