# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    Package['puppet-lint'] -> Class['contint::packages::labs']

    require contint::packages::apt

    include contint::packages
    # Fonts needed for browser tests screenshots (T71535)
    include mediawiki::packages::fonts

    # Required for python testing
    include ::contint::packages::python

    # Required for ruby testing
    include ::contint::packages::ruby

    include phabricator::arcanist

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git

    # jenkins-debian glue puppetization:
    file { '/mnt/pbuilder':
        ensure  => directory,
        require => Mount['/mnt'],
    }

    file { '/var/cache/pbuilder':
        ensure  => link,
        target  => '/mnt/pbuilder',
        require => File['/mnt/pbuilder'],
    }

    package { [
        # Let git-buidpackage find the Ubuntu/Debian release names
        'libdistro-info-perl',
        ]:
        ensure => present,
    }
    package { [
        'jenkins-debian-glue',
        'jenkins-debian-glue-buildenv',
        'jenkins-debian-glue-buildenv-git',
        'jenkins-debian-glue-buildenv-lintian',
        'jenkins-debian-glue-buildenv-piuparts',
        'jenkins-debian-glue-buildenv-taptools',
        ]:
            ensure  => latest,
            # cowbuilder file hierarchy needs to be created after the symlink
            # points to the mounted disk.
            require => File['/var/cache/pbuilder'],
    }
    # end of jenkins-debian glue puppetization

    package { [
        'npm',
        # For mediawiki/extensions/Collection/OfflineContentGenerator/latex_renderer
        # Provided by openstack::common:
        #'unzip',
        # provided by misc::contint::packages:
        #'librsvg2-bin',
        #'imagemagick',

        ]: ensure => present,
    }

    # For mediawiki/extensions/Collection/OfflineContentGenerator/bundler
    require_package('zip')

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

    if os_version('ubuntu >= trusty') {
        exec { '/usr/bin/apt-get -y build-dep hhvm':
            onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
        }

        # Work around PIL 1.1.7 expecting libs in /usr/lib T101550
        file { '/usr/lib/libjpeg.so':
            ensure => link,
            target => '/usr/lib/x86_64-linux-gnu/libjpeg.so',
        }
        file { '/usr/lib/libz.so':
            ensure => link,
            target => '/usr/lib/x86_64-linux-gnu/libz.so',
        }

        package { [
            'hhvm-dev',

            # Android SDK
            'gcc-multilib',
            'lib32z1',
            'lib32stdc++6',

            # Android emulation
            'qemu',

            ]: ensure => present,
        }

        exec {'jenkins-deploy kvm membership':
            unless  => "/bin/grep -q 'kvm\\S*jenkins-deploy' /etc/group",
            command => '/usr/sbin/usermod -aG kvm jenkins-deploy',
        }
    }

    if os_version( 'debian >= jessie') {
        include ::contint::packages::ops
    }
}
