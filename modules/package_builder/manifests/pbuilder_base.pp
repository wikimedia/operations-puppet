define package_builder::pbuilder_base(
    $distribution='trusty',
    $components='main universe',
    $mirror='http://nova.clouds.archive.ubuntu.com/ubuntu/',
    $basepath='/var/cache/pbuilder/base',
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
                        --basepath \"${basepath}-${distribution}.cow\" \
                        ${arg}"

    exec { "cowbuilder_init_${distribution}":
        command => $command,
        creates => "${basepath}-${distribution}.cow",
    }

    file { "/var/cache/pbuilder/hooks/D01apt.wikimedia.org-${distribution}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('package_builder/D01.apt.wikimedia.org.erb'),
    }
}
