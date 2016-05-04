# == Class contint::package_builder
#
# Setup cow images and jenkins-debian-glue
#
class contint::package_builder {

    # We dont want package builder all over the place. Safeguard.
    requires_os('Debian == jessie')

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git

    # jenkins-debian glue puppetization:
    file { '/mnt/pbuilder':
        ensure  => directory,
        # On extended disk provided by ci::slave::labs::common
        require => Mount['/mnt'],
    }

    file { '/var/cache/pbuilder':
        ensure  => link,
        target  => '/mnt/pbuilder',
        require => File['/mnt/pbuilder'],
    }

    class { '::package_builder':
        # We need /var/cache/pbuilder to be a symlink to /mnt
        # before cowbuilder/pbuilder is installed
        require  => [
            File['/var/cache/pbuilder'],
            File['/mnt/pbuilder'],
        ],
        # Cowdancer is confused by /var/cache/pbuilder being a symlink
        # causing it to fail to properly --update cow images. T125999
        basepath => '/mnt/pbuilder'
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

}
