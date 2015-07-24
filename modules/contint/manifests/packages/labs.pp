# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    Package['puppet-lint'] -> Class['contint::packages::labs']

    include contint::packages
    # Fonts needed for browser tests screenshots (T71535)
    include mediawiki::packages::fonts

    # Required for python testing
    include ::contint::packages::python

    class { 'apt::unattendedupgrades':
        ensure => absent,
    }

    apt::conf { 'unattended-upgrades-wikimedia':
        ensure   => absent,
        priority => '51',
        key      => 'Unattended-Upgrade::Allowed-Origins',
        # lint:ignore:single_quote_string_with_variables
        value    => 'Wikimedia:${distro_codename}-wikimedia',
        # lint:endignore
    }
    apt::conf { 'lower-periodic-randomsleep':
        ensure   => absent,
        priority => '51',
        key      => 'APT::Periodic::RandomSleep',
        value    => '300',
    }

    # Not meant to run hourly :/
    file { '/etc/cron.hourly/apt':
        ensure  => absent,
    }

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git

    # jenkins-debian glue puppetization:
    file { '/mnt/pbuilder':
        ensure  => directory,
        require => Mount['/mnt'],
    }

    file { '/data/project/debianrepo':
        ensure => directory,
        owner  => 'jenkins-deploy',
        group  => 'wikidev',
        mode   => '0775',
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
    ensure_packages(['zip'])


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
            'ruby2.0',
            # bundle/gem compile ruby modules:
            'ruby2.0-dev',

            'hhvm-dev',

            # Android SDK
            'gcc-multilib',
            'lib32z1',
            'lib32stdc++6',

            # Android emulation
            'qemu',

            ]: ensure => present,
        }

        exec {"jenkins-deploy kvm membership":
            unless => "/bin/grep -q 'kvm\\S*jenkins-deploy' /etc/group",
            command => "/usr/sbin/usermod -aG kvm jenkins-deploy",
        }
    }

    if os_version( 'debian >= jessie') {
        # Lint authdns templates & config
        include authdns::lint
    }
}
