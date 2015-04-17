# Class package_builder
# Packaging environment building class
#
# Actions:
#   Installs Debian package creation/building tools and creates environments to
#   help with easy package building.
#
# Usage:
#   include package_builder
class package_builder(
    $basepath='/var/cache/pbuilder',
) {
    class { 'package_builder::hooks':
        basepath => $basepath,
    }
    class { 'package_builder::environments':
        basepath => $basepath,
    }

    ensure_packages([
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'devscripts',
        'dh-make',
        'dh-autoreconf',
        'git-buildpackage',
        'zip',
        'unzip',
        'debian-archive-keyring',
        'ubuntu-archive-keyring',
    ])

    file { '/etc/pbuilderrc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('package_builder/pbuilderrc.erb'),
    }

    # Dependency info
    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    Package['cowbuilder'] -> Class['package_builder::environments']
    Package['cowbuilder'] -> Class['package_builder::hooks']
}
