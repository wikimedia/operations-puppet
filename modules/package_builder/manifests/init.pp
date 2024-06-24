# Class package_builder
# @summary Packaging environment building class
#   Installs Debian package creation/building tools and creates environments to
#   help with easy package building.
# @param basepath the base path to use
# @param extra_packages A hash of extrabackes to add to the base image i.e. distro => [packages]}
# @example
#   include package_builder
#   class {'package_builder':
#     extra_packages => {'buster' =>['eatmydata'] },
#   }
class package_builder(
    Stdlib::Unixpath                      $basepath       = '/var/cache/pbuilder',
    Hash[Debian::Codename, Array[String]] $extra_packages = {}
) {
    class { 'package_builder::hooks':
        basepath => $basepath,
    }
    class { 'package_builder::environments':
        basepath       => $basepath,
        extra_packages => $extra_packages,
    }

    systemd::timer::job { 'package_builder_Clean_up_build_directory':
        ensure        => present,
        user          => 'root',
        description   => 'Delete builds older the 2 weeks',
        command       => "/usr/bin/find ${basepath}/build -type f -daystart -mtime +14 -delete",
        ignore_errors => true,
        interval      => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 02:00:00',  # Every day at 2:00
        },
    }
    systemd::timer::job { 'package_builder_Clean_up_result_directory':
        ensure        => present,
        user          => 'root',
        description   => 'Delete results older the 6 months',
        command       => "/usr/bin/find ${basepath}/result -type f -daystart -mtime +180 -delete",
        ignore_errors => true,
        interval      => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 03:00:00',  # Every day at 3:00
        },
    }

    ensure_packages([
        'apache2-dev',
        'build-essential',
        'cdbs',
        'cowbuilder',
        'debhelper',
        'debian-archive-keyring',
        'debian-keyring',
        'devscripts',
        'dh-autoreconf',
        'dh-exec',
        'dh-golang',
        'dh-make',
        'dh-make-golang',
        'dh-php',
        'dh-python',
        'dh-sysuser',
        'equivs',
        'fakeroot',
        'gem2deb',
        'git-buildpackage',
        'gnome-pkg-tools',
        'gobject-introspection',
        'gradle',
        'ivy-debian-helper',
        'javahelper',
        'kernel-wedge',
        'libdistro-info-perl',
        'lintian',
        'maven-debian-helper',
        'maven-repo-helper',
        'openstack-pkg-tools',
        'patchutils',
        'php-dev',
        'piuparts',
        'pkg-kde-tools',
        'pkg-php-tools',
        'postgresql-server-dev-all',
        'python3-pbr',
        'python3-pytest-runner',
        'python3-setuptools',
        'python3-setuptools-scm',
        'quilt',
        'scons',
        'sphinx-common',
        'subversion',
        'unzip',
        'wdiff',
        'zip',
    ])

    if !debian::codename::ge('bookworm') {
        ensure_packages(['python-all'])
    }

    file { '/etc/pbuilderrc':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('package_builder/pbuilderrc.erb'),
    }

    if debian::codename::ge('bullseye') {
        ensure_packages(['node-babel7', 'pkg-js-tools'])
    }

    file { '/usr/share/lintian/profiles/wikimedia':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/share/lintian/profiles/wikimedia/main.profile':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/package_builder/wikimedia.profile',
    }

    file { '/usr/share/lintian/vendors/wikimedia':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        recurse => remote,
        source  => 'puppet:///modules/package_builder/lintian-wikimedia',
    }

    # Ship an apt configuration to integrate deb-src entries for older distros
    # simplifies fetching the source for older distros by using
    # "apt-get source foo=VERSION" on the package build host
    ['buster', 'bookworm'].each |String $dist| {
        apt::repository{"${dist}-wikimedia_source_only":
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${dist}-wikimedia",
            bin        => false,
            components => 'main',
        }
        apt::repository{"${dist}_source_only":
            uri        => 'http://mirrors.wikimedia.org/debian/',
            dist       => $dist,
            bin        => false,
            components => 'main non-free contrib',
        }

        $security_repo = ($dist == 'buster').bool2str("${dist}/updates", "${dist}-security")
        apt::repository{"${dist}-security_source_only":
            uri        => 'http://security.debian.org/debian-security',
            dist       => $security_repo,
            bin        => false,
            components => 'main non-free contrib',
        }
    }
    # Ship an apt configuration to integrate deb-src entries for unstable,
    # simplifies fetching the source by using"apt-get source foo=VERSION"
    apt::repository{'unstable_source_only':
        uri        => 'http://mirrors.wikimedia.org/debian',
        dist       => 'unstable',
        bin        => false,
        components => 'main non-free contrib',
    }

    file { '/etc/lintianrc':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/package_builder/lintianrc',
    }

    # Dependency info
    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    Package['cowbuilder'] -> Class['package_builder::environments']
    Package['cowbuilder'] -> Class['package_builder::hooks']
}
