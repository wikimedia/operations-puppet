# SPDX-License-Identifier: Apache-2.0
# @summary Class to build debs for Apereo CAS
class profile::idp::build {

    ensure_packages(['dpkg-dev', 'debhelper', 'dh-exec', 'build-essential'])

    wmflib::dir::mkdir_p('/srv/cas-build/cas')

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

    firewall::service { 'cas_build_rsync':
        proto  => 'tcp',
        port   => [873],
        srange => wmflib::role::hosts('apt_repo'),
    }

    profile::auto_restarts::service { 'rsync': }
}
