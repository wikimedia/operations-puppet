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

    if os_version('ubuntu == trusty || debian == jessie') {
        $php_dev='php5-dev'
        $dh_php='dh-php5'
    } else {
        $php_dev='php-dev'
        $dh_php='dh-php'
    }

    if os_version('debian >= stretch') {
        require_package('dh-make-golang')
    }

    require_package([
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'cdbs',
        'devscripts',
        'patchutils',
        'debian-keyring',
        'dh-make',
        'dh-autoreconf',
        'dh-golang',
        'dh-systemd',
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
        'kernel-wedge',
        'javahelper',
        'pkg-kde-tools',
        'subversion',
        'sphinx-common',
        'scons',
        'apache2-dev',
        'ivy-debian-helper',
        $php_dev,
        $dh_php,
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

    # Ship an apt configuration to integrate deb-src entries for jessie and
    # trusty, simplifies fetching the source for older distros by using
    # "apt-get source foo=VERSION" on the package build host
    file { '/etc/apt/sources.list.d/package-build-deb-src.list':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/package_builder/package-build-deb-src.list',
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
