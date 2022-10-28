# SPDX-License-Identifier: Apache-2.0
# == Class profile::ci::package_builder
#
# Setup cow images and jenkins-debian-glue
#
class profile::ci::package_builder (
    Hash[Debian::Codename, Array[String]] $extra_packages = lookup('profile::ci::package_builder::extra_packages'),
) {

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git

    # jenkins-debian glue puppetization:
    file { '/srv/pbuilder':
        ensure  => directory,
        # On extended disk provided by ci::slave::labs::common
        require => Mount['/srv'],
    }

    file { '/var/cache/pbuilder':
        ensure  => link,
        target  => '/srv/pbuilder',
        require => File['/srv/pbuilder'],
    }

    class { '::package_builder':
        # We need /var/cache/pbuilder to be a symlink to /srv
        # before cowbuilder/pbuilder is installed
        require        => [
            File['/var/cache/pbuilder'],
            File['/srv/pbuilder'],
        ],
        # Cowdancer is confused by /var/cache/pbuilder being a symlink
        # causing it to fail to properly --update cow images. T125999
        basepath       => '/srv/pbuilder',
        extra_packages => $extra_packages,
    }

    ensure_resource(
      'apt::repository',
      'component-ci',
      {
        'uri'        => 'http://apt.wikimedia.org/wikimedia',
        'dist'       => "${::lsbdistcodename}-wikimedia",
        'components' => 'component/ci',
        'source'     => false,
      }
    )
    package { [
        'jenkins-debian-glue',
        'jenkins-debian-glue-buildenv',
        ]:
            ensure  => present,
            require => [
              Apt::Repository['component-ci'],
              # cowbuilder file hierarchy needs to be created after the symlink
              # points to the mounted disk.
              File['/var/cache/pbuilder'],
            ],
    }
    # Buster has jenkins-debian-glue v0.20.0 and we need to patch
    # lintian-junit-report so it can work with Jenkins Xunit plugin 2.x or
    # later. T295719
    file { '/usr/local/bin/lintian-junit-report':
        source => 'puppet:///modules/profile/ci/lintian-junit-report',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

}
