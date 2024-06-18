# SPDX-License-Identifier: Apache-2.0
# @summary Class to build debs for Apereo CAS
class profile::idp::build {

    ensure_packages(['dpkg-dev', 'debhelper', 'dh-exec', 'build-essential'])

    file { '/srv/cas-build/cas':
        ensure => directory,
    }

    git::clone { 'operations/software/cas-overlay-template':
        ensure    => latest,
        owner     => 'root',
        group     => 'root',
        directory => '/srv/cas-build/cas',
    }

    if debian::codename::eq('bullseye') {
        ensure_packages(['default-jdk-headless'])

        # Set up an rsync module to allow easy copying of the built DEB
        class { 'rsync::server': }
        rsync::server::module { 'cas-build-result':
            path => '/srv/cas-build/',
        }

        firewall::service { 'cas_build_rsync':
            proto  => 'tcp',
            port   => [873],
            srange => wmflib::role::hosts('apt_repo'),
        }

        profile::auto_restarts::service { 'rsync': }

    } else {
        apt::package_from_component { 'openjdk-21':
            component => 'component/jdk21',
            packages  => ['openjdk-21-jre', 'openjdk-21-jre-headless', 'openjdk-21-jdk', 'openjdk-21-jdk-headless'],
        }
    }
}
