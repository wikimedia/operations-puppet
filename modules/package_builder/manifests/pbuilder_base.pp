# Definition pbuilder_base
define package_builder::pbuilder_base(
    $mirror='http://mirrors.wikimedia.org/debian',
    $distribution='jessie',
    $components='main',
    $architecture='amd64',
    $basepath='/var/cache/pbuilder',
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
                        --architecture ${architecture} \
                        --basepath \"${basepath}/base-${distribution}-${architecture}.cow\" \
                        --debootstrapopts --variant=buildd \
                        ${arg}"

    exec { "cowbuilder_init_${distribution}":
        command => $command,
        creates => "${basepath}/base-${distribution}.cow",
    }
}
