# SPDX-License-Identifier: Apache-2.0
# == Class profile::ci::package_builder
#
# Setup cow images and jenkins-debian-glue
#
class profile::ci::package_builder (
    Hash[Variant[Debian::Codename, Enum['default']], Array[String]] $extra_packages = lookup('profile::ci::package_builder::extra_packages'),
) {

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git

    # jenkins-debian glue puppetization:
    file { [
        '/srv/pbuilder',
        '/srv/pbuilder/aptcache',
    ]:
        ensure  => directory,
        # On extended disk provided by ci::slave::labs::common
        require => Mount['/srv'],
    }

    file { '/var/cache/pbuilder':
        ensure  => link,
        force   => true,
        target  => '/srv/pbuilder',
        require => File['/srv/pbuilder'],
    }

    class { 'package_builder':
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

    ensure_packages(['jenkins-debian-glue', 'jenkins-debian-glue-buildenv'])
}
