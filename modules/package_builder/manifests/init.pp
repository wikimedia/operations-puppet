# Class package_builder
# Packaging environment building class
#
# Actions:
#   Installs Debian package creation/building tools and creates environments to
#   help with easy package building.
#
# Parameters:
#   $basepath Untested, don't change it
# Usage:
#   include package_builder
class package_builder(
    $basepath='/var/cache/pbuilder',
) {
    include package_builder::hooks
    include package_builder::environments

    package { [
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
        ]:
        ensure => present,
    }

    file { '/etc/pbuilderrc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('package_builder/pbuilderrc.erb'),
    }
    file { "${basepath}/hooks":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Dependency info
    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    Package['cowbuilder'] -> File["${basepath}/hooks"]
    Package['cowbuilder'] -> Class['package_builder::environments']
    File["${basepath}/hooks"] -> Class['package_builder::hooks']
}
