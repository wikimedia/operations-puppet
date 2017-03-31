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
    class { '::package_builder::hooks':
        basepath => $basepath,
    }
    class { '::package_builder::environments':
        basepath => $basepath,
    }

    require_package([
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'cdbs',
        'devscripts',
        'debian-keyring',
        'dh-make',
        'dh-autoreconf',
        'dh-php5',
        'dh-golang',
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
        'libdistro-info-perl',
        'maven-repo-helper',
        'gradle',
        'pkg-php-tools',
        'php5-dev',
        'kernel-wedge',
        'javahelper',
        'pkg-kde-tools',
        'subversion',
    ])

    if $::operatingsystem == 'Ubuntu' {
        require_package('ubuntu-keyring')
    } else {
        require_package('ubuntu-archive-keyring')
    }

    file { '/etc/pbuilderrc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('package_builder/pbuilderrc.erb'),
    }

    file { '/usr/share/lintian/profiles/wikimedia':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['lintian'],
    }

    file { '/usr/share/lintian/profiles/wikimedia/main.profile':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/package_builder/wikimedia.profile',
        require => File['/usr/share/lintian/profiles/wikimedia'],
    }

    file { '/usr/share/lintian/vendors/wikimedia':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        recurse => remote,
        source  => 'puppet:///modules/package_builder/lintian-wikimedia',
        require => Package['lintian'],
    }

    file { '/etc/lintianrc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/package_builder/lintianrc',
        require => Package['lintian'],
    }

    # Dependency info
    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    Package['cowbuilder'] -> Class['package_builder::environments']
    Package['cowbuilder'] -> Class['package_builder::hooks']
}
