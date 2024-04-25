# SPDX-License-Identifier: Apache-2.0
# @summary Class to build debs for Apereo CAS
class profile::idp::build {

    ensure_packages(['dpkg-dev', 'debhelper'])
    ensure_packages(['dh-exec', 'build-essential', 'default-jdk-headless'])

    file { '/srv/cas-build/cas':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    git::clone { 'operations/software/cas-overlay-template':
        ensure    => latest,
        owner     => 'root',
        group     => 'root',
        directory => '/srv/cas-build/cas',
    }

    # Set up an rsync module to allow easy copying of the built DEB
    class { 'rsync::server': }
    rsync::server::module { 'cas-build-result':
        path => '/srv/cas-build/',
    }

    profile::auto_restarts::service { 'rsync': }

    firewall::service { 'cas_build_rsync':
        proto  => 'tcp',
        port   => [873],
        srange => wmflib::role::hosts('apt_repo'),
    }
}
