# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    Package['puppet-lint'] -> Class['contint::packages::labs']

    include contint::packages
    # Fonts needed for browser tests screenshots (bug 69535)
    include mediawiki::packages::fonts

    # Self update the wikimedia packages (such as hhvm) on an hourly basis
    include apt::unattendedupgrades

    apt::conf { 'unattended-upgrades-wikimedia':
        priority => '51',
        key      => 'Unattended-Upgrade::Allowed-Origins',
        # lint:ignore:single_quote_string_with_variables
        value    => 'Wikimedia:${distro_codename}-wikimedia',
        # lint:endignore
    }
    apt::conf { 'lower-periodic-randomsleep':
        priority => '51',
        key      => 'APT::Periodic::RandomSleep',
        value    => '300',
    }

    file { '/etc/cron.hourly/apt':
        ensure  => link,
        target  => '/etc/cron.daily/apt',
        require => Package['unattended-upgrades'],
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

        # Let us compile python modules:
        'python-dev',
        'libmysqlclient-dev',  # For python SQLAlchemy

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

    # Also provided by Zuul installation
    ensure_packages(['python-pip'])

    # Bring tox/virtualenv... from pip  bug 44443
    # TODO: Reevaluate this once we switch to trusty. Maybe provider being apt
    # would be better then
    package { 'tox':
        ensure   => present,
        provider => 'pip',
        require  => Package['python-pip'],
    }

    if os_version('ubuntu >= trusty') {
        exec { '/usr/bin/apt-get -y build-dep hhvm':
            onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
        }

        package { [
            'python3.4',
            # Let us compile python modules:
            'python3.4-dev',

            'ruby2.0',
            # bundle/gem compile ruby modules:
            'ruby2.0-dev',

            'hhvm-dev',

            ]: ensure => present,
        }
    }

}
