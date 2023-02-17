# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::puppetmaster::common () {
    include profile::openstack::base::puppetmaster::enc_client

    # Update Puppet git repositories
    class { 'puppetmaster::gitsync':
        run_every_minutes => 1,
    }

    ferm::service { 'puppetmaster':
        proto  => 'tcp',
        port   => '8141',
        srange => '$LABS_NETWORKS',
    }
}
