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

    require_package([
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'cdbs',
        'devscripts',
        'dh-make',
        'dh-autoreconf',
        'openstack-pkg-tools',
        'git-buildpackage',
        'quilt',
        'wdiff',
        'lintian',
        'zip',
        'unzip',
        'debian-archive-keyring',
        'gnome-pkg-tools',
        'gobject-introspection',
    ])

    if $::operatingsystem == 'Ubuntu' {
        require_package('ubuntu-keyring')
    } else {
        require_package('ubuntu-archive-keyring')
    }

    if os_version('ubuntu < trusty') {
        # we cannot build debian debootstrap environments on old ubuntu hosts (T111730)
        fail('package_builder requires ubuntu >= trusty')
    }

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
